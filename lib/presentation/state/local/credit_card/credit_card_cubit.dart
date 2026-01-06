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

  bool _isBusy = false;

  Future<void> processImage(CameraImage image, CameraDescription camera) async {
    if (_isBusy || state.status == CreditCardStatus.success) return;

    _isBusy = true;
    // 너무 빠른 UI 갱신을 막기 위해 상태 변경은 생략하거나 필요시에만 합니다.
    // emit(state.copyWith(status: CreditCardStatus.processing));

    try {
      final InputImage? inputImage = CameraUtils.convertCameraImageToInputImage(
        image,
        camera,
      );

      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      _parseText(recognizedText);
    } catch (e) {
      debugPrint("OCR Error: $e");
    } finally {
      _isBusy = false;
    }
  }

  void _parseText(RecognizedText recognizedText) {
    String? foundCardNumber;

    // [전략] N줄 합치기 (1~4줄)
    outerLoop:
    for (final block in recognizedText.blocks) {
      final lines = block.lines;

      for (int i = 0; i < lines.length; i++) {
        // 기존의 _isIgnoredPattern 같은 복잡한 정규식 제거
        // 대신 아래의 강력한 _extractCardNumber가 모든 것을 걸러냅니다.

        String combinedText = "";

        // i번째 줄부터 최대 4줄까지 합쳐보기
        for (int j = 0; j < 4; j++) {
          if (i + j >= lines.length) break;

          combinedText += "${lines[i + j].text} ";

          // 검사
          String? result = _extractCardNumber(combinedText);
          if (result != null) {
            foundCardNumber = result;
            break outerLoop;
          }
        }
      }
    }

    // ---------------------------------------------------------
    // 유효기간 추출
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

  /// [핵심 수정] 숫자 추출 및 검증 로직
  String? _extractCardNumber(String text) {
    String numbersOnly = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbersOnly.length < 13 || numbersOnly.length > 19) return null;
    if (numbersOnly.startsWith(RegExp(r'[012]'))) {
      // debugPrint(">>> 전화번호로 의심되어 무시함: $numbersOnly");
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
