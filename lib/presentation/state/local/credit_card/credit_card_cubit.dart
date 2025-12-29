import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

part 'credit_card_cubit.freezed.dart';
part 'credit_card_state.dart';

class CreditCardCubit extends Cubit<CreditCardState> {
  CreditCardCubit() : super(const CreditCardState());

  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<void> processImage(BarcodeCapture capture) async {
    if (state.status == CreditCardStatus.processing) return;

    if (capture.image == null) {
      return;
    }

    emit(state.copyWith(status: CreditCardStatus.processing));

    try {
      final ui.Image decodedImage = await decodeImageFromList(capture.image!);

      final int width = decodedImage.width;
      final int height = decodedImage.height;

      final ByteData? byteData = await decodedImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (byteData == null) {
        throw Exception("Failed to convert image to byte data.");
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      final InputImage inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: width * 4,
        ),
      );

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      debugPrint("===== OCR Raw Text =====");
      debugPrint(recognizedText.text);
      debugPrint("========================");

      _parseText(recognizedText.text);
    } catch (e) {
      debugPrint("이미지 처리 중 오류 발생: $e");
      emit(state.copyWith(status: CreditCardStatus.error));
    }
  }

  void _parseText(String text) {
    final RegExp cardRegExp = RegExp(r'(?:\d{4}[-\s]?){3}\d{1,4}');
    final String? rawCardNumber = cardRegExp.firstMatch(text)?.group(0);
    final String? cardNumber = rawCardNumber?.replaceAll(RegExp(r'[-\s]'), '');

    final RegExp expiryRegExp = RegExp(r'(0[1-9]|1[0-2])\s*[/.-]\s*([0-9]{2})');
    final RegExpMatch? expiryMatch = expiryRegExp.firstMatch(text);
    final String? expiryDate = expiryMatch != null
        ? '${expiryMatch.group(1)}/${expiryMatch.group(2)}'
        : null;

    if (cardNumber != null) {
      emit(
        state.copyWith(
          status: CreditCardStatus.success,
          cardNumber: cardNumber,
          expiryDate: expiryDate ?? 'N/A',
        ),
      );
    } else {
      emit(state.copyWith(status: CreditCardStatus.notFound));
    }
  }

  @override
  Future<void> close() {
    _textRecognizer.close();
    return super.close();
  }
}
