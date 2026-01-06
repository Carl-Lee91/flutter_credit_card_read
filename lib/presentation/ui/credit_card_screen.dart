import 'dart:io';

import 'package:camera/camera.dart';
import 'package:credit_card_read/presentation/state/local/credit_card/credit_card_cubit.dart';
import 'package:credit_card_read/presentation/ui/credit_card_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

class TextScannerView extends StatefulWidget {
  const TextScannerView({super.key});

  @override
  State<TextScannerView> createState() => _TextScannerViewState();
}

class _TextScannerViewState extends State<TextScannerView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  CameraDescription? _camera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isDenied) {
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      _camera!,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      await _cameraController!.startImageStream((CameraImage image) {
        if (_camera != null) {
          context.read<CreditCardCubit>().processImage(image, _camera!);
        }
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("카메라 초기화 오류: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('신용카드 스캐너 (Camera)')),
        body: BlocListener<CreditCardCubit, CreditCardState>(
          listener: (context, state) {
            if (state.status == CreditCardStatus.success) {
              _cameraController?.stopImageStream();

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CreditCardResultScreen(
                    cardNumber: state.cardNumber ?? '',
                    expiryDate: state.expiryDate ?? "",
                  ),
                ),
              );
            }
          },
          child: Stack(
            children: [
              if (_isCameraInitialized && _cameraController != null)
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CameraPreview(_cameraController!),
                )
              else
                const Center(child: CircularProgressIndicator()),

              Center(
                child: Container(
                  width: 350,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
