import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';

class RefereeCheckInScreen extends StatelessWidget {
  final String matchId;

  const RefereeCheckInScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    // Payload as per instructions
    final String qrData = jsonEncode({
      'match_id': matchId,
      'action': 'check_in',
    });

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'Check-in de Jugadores',
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kwhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kpurple1.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: MediaQuery.of(context).size.width * 0.7,
                  foregroundColor: kpurple1,
                ),
              ),
            ),
            const SizedBox(height: 48),
            MyText(
              text: 'Pide a los jugadores que escaneen este código desde la app',
              size: 18,
              weight: FontWeight.w600,
              color: kblack2,
              textAlign: TextAlign.center,
              paddingBottom: 8,
            ),
            MyText(
              text: 'Al escanearlo, su asistencia quedará confirmada automáticamente.',
              size: 14,
              color: kgrey1,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // Just for good measure, remind user of match id
            MyText(
              text: 'Match ID: ${matchId.substring(0, 8)}...',
              size: 12,
              color: kgrey2,
              textAlign: TextAlign.center,
              paddingBottom: 20,
            ),
          ],
        ),
      ),
    );
  }
}
