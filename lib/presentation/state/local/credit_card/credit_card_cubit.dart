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
    String? foundCardNumber;

    // 1. 전략 A: 기존 방식 (줄바꿈만 공백으로 치환 후 정규식)
    //    장점: 카드 번호 형식이 잘 지켜진 경우 오탐이 적음
    //    단점: 중간에 이상한 글자가 끼어있으면 실패함
    foundCardNumber = _parseCardNumberStrategyA(text);

    // 2. 전략 B: 공격적 추출 (모든 숫자만 뽑아서 13~19자리 검사)
    //    장점: 줄바꿈, 중간 텍스트(VALID THRU 등)가 섞여 있어도 찾아냄
    foundCardNumber ??= _parseCardNumberStrategyB(text);

    // ---------------------------------------------------------
    // 유효기간 추출 개선
    // ---------------------------------------------------------
    // MM/YY, MM/YYYY, MM-YY, MM.YY 등 다양한 구분자 허용
    // 공백(\s*)을 좀 더 유연하게 허용
    final RegExp expiryRegExp = RegExp(
      r'(0[1-9]|1[0-2])\s*[/.-]\s*([0-9]{2,4})',
    );
    // 전체 텍스트에서 찾기
    final RegExpMatch? expiryMatch = expiryRegExp.firstMatch(text);
    String? expiryDate;

    if (expiryMatch != null) {
      String month = expiryMatch.group(1)!;
      String year = expiryMatch.group(2)!;
      if (year.length == 4) year = year.substring(2);
      expiryDate = '$month/$year';
    }

    if (foundCardNumber != null) {
      emit(
        state.copyWith(
          status: CreditCardStatus.success,
          cardNumber: foundCardNumber,
          expiryDate: expiryDate ?? 'N/A',
        ),
      );
    } else {
      // 못 찾았을 경우
      // emit(state.copyWith(status: CreditCardStatus.notFound));
    }
  }

  /// 전략 A: 기존 방식 (줄바꿈 -> 공백 치환 후 정규식)
  String? _parseCardNumberStrategyA(String text) {
    String cleanedOneLine = text.replaceAll('\n', ' ');
    // 숫자 덩어리 찾기 (공백, 대시 허용)
    final RegExp cardRegExp = RegExp(r'(?:[0-9][-\s]*){13,19}');
    final Iterable<RegExpMatch> matches = cardRegExp.allMatches(cleanedOneLine);

    for (final match in matches) {
      final String raw = match.group(0) ?? '';
      final String candidate = raw.replaceAll(RegExp(r'[^0-9]'), '');

      if (candidate.length < 13 || candidate.length > 19) continue;

      if (_isValidLuhn(candidate)) {
        debugPrint(">>> 전략 A 성공: $candidate");
        return candidate;
      }
    }
    return null;
  }

  /// 전략 B: 공격적 추출 (모든 숫자 연결 후 탐색)
  String? _parseCardNumberStrategyB(String text) {
    // 1. 텍스트에서 숫자만 싹 긁어모음
    final String allDigits = text.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. 숫자가 너무 적으면 패스
    if (allDigits.length < 13) return null;

    // 3. Sliding Window 방식으로 13~16(또는 19)자리 숫자를 잘라서 룬 알고리즘 체크
    //    카드 번호가 16자리라고 가정할 때, 앞뒤로 다른 숫자가 붙어있을 수 있으므로
    //    가능한 모든 부분 문자열을 검사합니다.
    //    일반적으로 카드번호는 13~16자리 (Visa/Master 16, Amex 15, Diners 14 등)
    //    최대 19자리까지 가능하다고 봄.

    // 긴 숫자열에서 유효한 카드번호 찾기
    // 예: "01012345678" + "4111111111111111" + "2025"
    // 이런 식으로 붙어버릴 수 있음.

    // 가장 긴 가능성부터 체크 (16자리 우선)
    const List<int> lengthsToCheck = [16, 15, 14, 13];

    for (int len in lengthsToCheck) {
      for (int i = 0; i <= allDigits.length - len; i++) {
        String candidate = allDigits.substring(i, i + len);
        if (_isValidLuhn(candidate)) {
          debugPrint(">>> 전략 B 성공: $candidate");
          return candidate;
        }
      }
    }

    return null;
  }

  /// [Luhn Algorithm]
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
