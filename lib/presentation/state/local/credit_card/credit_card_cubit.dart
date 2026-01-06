import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';

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
      final Uint8List imageBytes = capture.image!;

      final tempDir = await getTemporaryDirectory();

      final File file = await File(
        '${tempDir.path}/ocr_temp_image.jpg',
      ).create();

      await file.writeAsBytes(imageBytes);

      final InputImage inputImage = InputImage.fromFilePath(file.path);

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

      await Future.delayed(const Duration(seconds: 1));
      if (!isClosed) emit(state.copyWith(status: CreditCardStatus.initial));
    }
  }

  void _parseText(String text) {
    // 1. [핵심] 줄바꿈(\n)을 모두 공백으로 바꿔서 텍스트를 "한 줄"로 만듭니다.
    // 이렇게 하면 세로로 적힌 카드(0000\n0000...)도 가로로 적힌 것처럼(0000 0000...) 변합니다.
    String cleanedOneLine = text.replaceAll('\n', ' ');

    debugPrint("--- 분석 대상 텍스트: $cleanedOneLine");

    // 2. 숫자 덩어리를 찾는 광범위한 정규식
    // 설명: 숫자가 나오는데, 사이사이에 공백(\s)이나 대시(-)가 섞여 있어도 쭉 긁어옵니다.
    // 최소 13자 이상 이어지는 숫자 패턴을 찾습니다.
    final RegExp cardRegExp = RegExp(r'(?:[0-9][-\s]*){13,19}');

    final Iterable<RegExpMatch> matches = cardRegExp.allMatches(cleanedOneLine);

    String? foundCardNumber;

    for (final match in matches) {
      final String raw = match.group(0) ?? '';

      // 3. 숫자만 남기고 나머지(공백, 대시 등) 제거
      final String candidate = raw.replaceAll(RegExp(r'[^0-9]'), '');

      // 4. 길이 재확인 (13~16자리, 일부 카드는 19자리까지)
      if (candidate.length < 14 || candidate.length > 17) continue;

      // 5. 룬 알고리즘 체크
      debugPrint("후보군 검사 중: $candidate");
      if (_isValidLuhn(candidate)) {
        foundCardNumber = candidate;
        debugPrint(">>> 유효한 카드 번호 발견: $foundCardNumber");
        break; // 찾았으면 반복 종료
      } else {
        debugPrint(">>> 룬 알고리즘 실패 (아마도 전화번호 등): $candidate");
      }
    }

    // ---------------------------------------------------------
    // 유효기간 추출 (이전과 동일)
    final RegExp expiryRegExp = RegExp(
      r'(0[1-9]|1[0-2])\s*[/.-]\s*([0-9]{2,4})',
    );
    final RegExpMatch? expiryMatch = expiryRegExp.firstMatch(
      text,
    ); // 원본 text 사용
    String? expiryDate;

    if (expiryMatch != null) {
      String month = expiryMatch.group(1)!;
      String year = expiryMatch.group(2)!;
      if (year.length == 4) year = year.substring(2);
      expiryDate = '$month/$year';
    }
    // ---------------------------------------------------------

    if (foundCardNumber != null) {
      emit(
        state.copyWith(
          status: CreditCardStatus.success,
          cardNumber: foundCardNumber,
          expiryDate: expiryDate ?? 'N/A',
        ),
      );
    } else {
      // 못 찾았으면 계속 찾도록 둠 (notFound 상태로 바꾸면 화면이 깜빡일 수 있으니 유지하거나 신중히 처리)
      // emit(state.copyWith(status: CreditCardStatus.notFound));
    }
  }

  /// [Luhn Algorithm] (변동 없음)
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
