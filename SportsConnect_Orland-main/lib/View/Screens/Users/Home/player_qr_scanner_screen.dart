import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_creation_controller.dart';

class PlayerQRScannerScreen extends StatefulWidget {
  const PlayerQRScannerScreen({super.key});

  @override
  State<PlayerQRScannerScreen> createState() => _PlayerQRScannerScreenState();
}

class _PlayerQRScannerScreenState extends State<PlayerQRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null) {
        debugPrint('Barcode found! $rawValue');
        setState(() => isProcessing = true);

        try {
          final Map<String, dynamic> data = jsonDecode(rawValue);
          
          // Validate format
          if (data['action'] == 'check_in' && data['match_id'] != null) {
            final String matchId = data['match_id'];
            
            final matchController = Get.find<MatchCreationController>();
            final success = await matchController.confirmCheckIn(matchId);
            
            if (success) {
              // Close scanner and go back to home
              if (mounted) {
                Get.back();
              }
              return;
            } else {
              // Logic in controller already shows failure toast if it's a known error
              setState(() => isProcessing = false);
            }
          } else {
            _showError('Código no válido: Formato incorrecto.');
            setState(() => isProcessing = false);
          }
        } catch (e) {
          _showError('Código no válido: No es un QR de Matchmake.');
          setState(() => isProcessing = false);
        }
      }
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error de Escaneo',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar2(
        title: 'Escanear Check-in',
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: kpurple1, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                MyText(
                  text: 'Apunta al código QR del árbitro',
                  size: 16,
                  weight: FontWeight.bold,
                  color: kwhite,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                MyText(
                  text: 'El proceso será automático al detectar el código.',
                  size: 14,
                  color: kwhite.withOpacity(0.8),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Loading Indicator
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: kpurple1),
              ),
            ),
        ],
      ),
    );
  }
}
