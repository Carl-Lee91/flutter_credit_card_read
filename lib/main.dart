import 'package:credit_card_read/presentation/state/local/credit_card/credit_card_cubit.dart';
import 'package:credit_card_read/presentation/ui/credit_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      home: BlocProvider(
        create: (context) => CreditCardCubit(),
        child: const TextScannerView(),
      ),
    );
  }
}
