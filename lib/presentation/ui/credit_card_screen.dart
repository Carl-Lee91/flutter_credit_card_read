import 'package:credit_card_read/presentation/state/local/credit_card/credit_card_cubit.dart'; // 경로 확인 필요
import 'package:credit_card_read/presentation/ui/credit_card_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TextScannerScreen extends StatelessWidget {
  const TextScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreditCardCubit(),
      child: const TextScannerView(),
    );
  }
}

class TextScannerView extends StatefulWidget {
  const TextScannerView({super.key});

  @override
  State<TextScannerView> createState() => _TextScannerViewState();
}

class _TextScannerViewState extends State<TextScannerView> {
  // 컨트롤러를 상태 변수로 관리합니다.
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      returnImage: true,
      detectionSpeed: DetectionSpeed.normal,
      // torchEnabled: false, // 필요 시 설정
    );
  }

  @override
  void dispose() {
    // 화면이 꺼질 때 컨트롤러를 정리합니다.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('신용카드 스캐너')),
        // BlocListener를 사용하여 상태 변화(성공)를 감지합니다.
        body: BlocListener<CreditCardCubit, CreditCardState>(
          listener: (context, state) {
            if (state.status == CreditCardStatus.success) {
              // 1. 성공 시 스캐너 정지 (배터리 절약 및 중복 스캔 방지)
              _controller.stop();

              // 2. 결과 화면으로 이동 (Replacement를 쓰면 뒤로가기 시 스캐너로 안 돌아옴)
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CreditCardResultScreen(
                    cardNumber: state.cardNumber ?? '',
                    expiryDate: state.expiryDate ?? '',
                  ),
                ),
              );
            }
          },
          child: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  // Cubit에 이미지 처리를 요청합니다.
                  context.read<CreditCardCubit>().processImage(capture);
                },
              ),
              // 화면 위에 상태 메시지나 로딩 표시
              BlocBuilder<CreditCardCubit, CreditCardState>(
                builder: (context, state) {
                  if (state.status == CreditCardStatus.processing) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  // 스캔 가이드라인 박스 (선택 사항)
                  return Center(
                    child: Container(
                      width: 350,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.topCenter,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "카드를 영역 안에 맞춰주세요",
                          style: TextStyle(
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
