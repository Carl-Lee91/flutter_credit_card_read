import 'package:credit_card_read/presentation/state/local/credit_card/credit_card_cubit.dart';
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

class TextScannerView extends StatelessWidget {
  const TextScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('신용카드 스캐너 (Clean Arch)')),
        body: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                context.read<CreditCardCubit>().processImage(capture);
              },
            ),
            BlocBuilder<CreditCardCubit, CreditCardState>(
              builder: (context, state) {
                Widget bottomWidget;
                if (state.status == CreditCardStatus.processing) {
                  bottomWidget = const Center(
                    child: CircularProgressIndicator(),
                  );
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
      ),
    );
  }
}
