import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/BottomNavBars/BottomNavbar.dart';
import 'package:orland_sports/View/Widgets/DialogBoxes.dart';
import 'package:orland_sports/View/Widgets/SummaryCard.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/enums/match_status.dart' as enums;

class ReviewSummary extends StatelessWidget {
  final Future<bool> Function() onConfirm;

  const ReviewSummary({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final RxBool isProcessing = false.obs;
    final RxBool hasBalls = false.obs; // Equipment Rule

    // ── Resolve real club/court name from MatchController ──────────────────
    final matchCtrl = Get.find<MatchController>();

    final String locationLabel;
    if (matchCtrl.preferredClubIds.isNotEmpty) {
      final count = matchCtrl.preferredClubIds.length;
      locationLabel = '$count club${count == 1 ? '' : 's'} seleccionado${count == 1 ? '' : 's'}';
    } else if (matchCtrl.selectedCourt.value != null) {
      locationLabel = matchCtrl.selectedCourt.value!.name;
    } else {
      locationLabel = 'Club por asignar';
    }

    final String matchTypeName =
        matchCtrl.selectedMatchType.value == enums.MatchType.oneVsOne
            ? '1v1 · ${matchCtrl.selectedCategory.value}'
            : '2v2 · ${matchCtrl.selectedCategory.value}';

    final String timeLabel =
        '${matchCtrl.selectedTimeSlot.value} → ${matchCtrl.selectedEndTimeSlot.value}';

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'Confirmar Partido',
        haveBackButton: true,
        centerTitle: false,
        actions: [ticketcount(), const SizedBox(width: 13)],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 20),
                summaryCard(
                  matchType: matchTypeName,
                  court: locationLabel,
                  text1: 'Horario',
                  text2: timeLabel,
                ),
                const SizedBox(height: 20),
                Obx(() => Container(
                      decoration: BoxDecoration(
                        color: hasBalls.value ? kpurple1.withOpacity(0.05) : kgrey2.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: hasBalls.value ? kpurple1 : kgrey2),
                      ),
                      child: CheckboxListTile(
                        value: hasBalls.value,
                        activeColor: kpurple1,
                        checkColor: kwhite,
                        onChanged: (val) => hasBalls.value = val ?? false,
                        title: const Text(
                          'Me comprometo a llevar al menos 2 pelotas en buen estado al partido',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    )),
              ],
            ),
          ),
          Obx(() => MyButton(
                onTap: (isProcessing.value || !hasBalls.value)
                    ? () {
                        if (!hasBalls.value) {
                          ScaffoldMessenger.of(Get.context!).showSnackBar(
                            const SnackBar(
                              content: Text('Debes comprometerte a llevar pelotas para continuar.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    : () async {
                        print('🔥 INTENTO DE PAGO INICIADO');
                        isProcessing.value = true;
                        try {
                          final success = await onConfirm();
                          isProcessing.value = false;
                          if (success) {
                            SuccessDialog.showSuccessDialog(
                              'Exitoso',
                              '¡Partido confirmado correctamente!',
                              ontap: () {
                                Get.offAll(() => BottomNavBar());
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(Get.context!).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo confirmar. Verifica tu saldo e inténtalo de nuevo.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        } catch (e) {
                          isProcessing.value = false;
                          print('🔥 ERROR TICKET: $e');
                          ScaffoldMessenger.of(Get.context!).showSnackBar(
                            SnackBar(
                              content: Text('Error inesperado: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                buttonText: isProcessing.value
                    ? 'Procesando...'
                    : 'Gastar 1 Pase y Confirmar',
                fillColor: hasBalls.value ? kpurple1 : kgrey1,
                mhoriz: 20,
                mBottom: 40,
              )),
        ],
      ),
    );
  }
}
