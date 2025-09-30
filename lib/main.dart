import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

part 'main.freezed.dart';

// -- 1. State와 Cubit 정의 (원래는 별도 파일로 분리하는 것이 좋습니다) --

// State 정의
enum CreditCardStatus { initial, processing, success, notFound, error }

@freezed
abstract class CreditCardState with _$CreditCardState {
  const factory CreditCardState({
    @Default(CreditCardStatus.initial) CreditCardStatus status,
    String? cardNumber,
    String? expiryDate,
  }) = _CreditCardState;
}

// Cubit 정의
class CreditCardCubit extends Cubit<CreditCardState> {
  CreditCardCubit() : super(const CreditCardState());

  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<void> processImage(BarcodeCapture capture) async {
    if (state.status == CreditCardStatus.processing) return;

    if (capture.image == null) return;

    emit(state.copyWith(status: CreditCardStatus.processing));

    try {
      final InputImage inputImage = InputImage.fromBytes(
        bytes: capture.image!,
        metadata: InputImageMetadata(
          size: Size(
            capture.size.width.toDouble(),
            capture.size.height.toDouble(),
          ),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: 0,
        ),
      );

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      _parseText(recognizedText.text);
    } catch (e) {
      emit(state.copyWith(status: CreditCardStatus.error));
    }
  }

  void _parseText(String text) {
    final String sanitizedText = text.replaceAll(RegExp(r'[^0-9]'), '');
    final RegExp cardRegExp = RegExp(r'\b\d{13,16}\b');
    final RegExp expiryRegExp = RegExp(r'\b(0[1-9]|1[0-2])\/?([0-9]{2})\b');

    final String? cardNumber = cardRegExp.firstMatch(sanitizedText)?.group(0);
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

// -- 앱 실행 부분 --

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '신용카드 스캐너',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // MyHomePage 대신 TextScannerScreen을 홈으로 지정
      home: const TextScannerScreen(),
    );
  }
}

// -- UI 위젯 부분 --

class TextScannerScreen extends StatelessWidget {
  const TextScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cubit을 위젯 트리에 제공
    return BlocProvider(
      create: (context) => CreditCardCubit(),
      child: const TextScannerView(),
    );
  }
}

class TextScannerView extends StatelessWidget {
  const TextScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('신용카드 스캐너 (Bloc)')),
      body: Stack(
        children: [
          // MobileScanner로 카메라 화면 표시
          MobileScanner(
            onDetect: (capture) {
              // 감지된 이미지를 Cubit으로 전달
              context.read<CreditCardCubit>().processImage(capture);
            },
          ),
          // BlocBuilder로 상태 변화에 따라 UI 업데이트
          BlocBuilder<CreditCardCubit, CreditCardState>(
            builder: (context, state) {
              Widget bottomWidget;
              if (state.status == CreditCardStatus.processing) {
                bottomWidget = const Center(child: CircularProgressIndicator());
              } else if (state.status == CreditCardStatus.success) {
                bottomWidget = Text(
                  '카드 번호: ${state.cardNumber}\n유효 기간: ${state.expiryDate}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    backgroundColor: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                );
              } else {
                bottomWidget = const Text(
                  '카드를 화면 중앙에 비춰주세요.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    backgroundColor: Colors.black54,
                  ),
                );
              }
              return Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(32.0),
                child: bottomWidget,
              );
            },
          ),
        ],
      ),
    );
  }
}
