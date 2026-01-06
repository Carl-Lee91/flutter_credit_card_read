import 'package:camera/camera.dart';
import 'package:credit_card_read/presentation/ui/camera_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

part 'credit_card_cubit.freezed.dart';
part 'credit_card_state.dart';

class CreditCardCubit extends Cubit<CreditCardState> {
  CreditCardCubit() : super(const CreditCardState());

  final TextRecognizer _textRecognizer = TextRecognizer();

  void setCameraInitialized() {
    emit(state.copyWith(isCameraInitialized: true));
  }

  Future<void> processImage(CameraImage image, CameraDescription camera) async {
    if (state.status == CreditCardStatus.processing ||
        state.status == CreditCardStatus.success) {
      return;
    }

    emit(state.copyWith(status: CreditCardStatus.processing));

    try {
      final InputImage? inputImage = CameraUtils.convertCameraImageToInputImage(
        image,
        camera,
      );

      if (inputImage == null) {
        emit(state.copyWith(status: CreditCardStatus.initial));
        return;
      }

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      _parseText(recognizedText);
    } catch (e) {
      debugPrint("OCR Error: $e");
    } finally {
      emit(state.copyWith(status: CreditCardStatus.initial));
    }
  }

  void _parseText(RecognizedText recognizedText) {
    String? foundCardNumber;

    outerLoop:
    for (final block in recognizedText.blocks) {
      final lines = block.lines;

      for (int i = 0; i < lines.length; i++) {
        String combinedText = "";

        for (int j = 0; j < 4; j++) {
          if (i + j >= lines.length) break;

          combinedText += "${lines[i + j].text} ";

          String? result = _extractCardNumber(combinedText);
          if (result != null) {
            foundCardNumber = result;
            break outerLoop;
          }
        }
      }
    }

    final String fullText = recognizedText.text;
    final RegExp expiryRegExp = RegExp(
      r'(0[1-9]|1[0-2])\s*[/.-]\s*([0-9]{2,4})',
    );
    final RegExpMatch? expiryMatch = expiryRegExp.firstMatch(fullText);
    String? expiryDate;

    if (expiryMatch != null) {
      String month = expiryMatch.group(1)!;
      String year = expiryMatch.group(2)!;
      if (year.length == 4) year = year.substring(2);
      expiryDate = '$month/$year';
    }

    if (foundCardNumber != null) {
      debugPrint(">>> 최종 찾은 카드 번호: $foundCardNumber");
      emit(
        state.copyWith(
          status: CreditCardStatus.success,
          cardNumber: foundCardNumber,
          expiryDate: expiryDate ?? 'N/A',
        ),
      );
    } else {
      emit(state.copyWith(status: CreditCardStatus.initial));
    }
  }

  String? _extractCardNumber(String text) {
    String numbersOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbersOnly.length < 15 || numbersOnly.length > 17) return null;
    if (numbersOnly.startsWith(RegExp(r'[012]'))) {
      return null;
    }

    if (_isValidLuhn(numbersOnly)) {
      return numbersOnly;
    }

    return null;
  }

  bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool isSecond = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      if (isSecond) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      isSecond = !isSecond;
    }
    return (sum % 10 == 0);
  }

  @override
  Future<void> close() {
    _textRecognizer.close();
    return super.close();
  }
}
