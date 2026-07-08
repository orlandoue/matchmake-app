import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/BottomNavBars/BottomNavbar.dart';
import 'package:orland_sports/View/Widgets/DialogBoxes.dart';
import 'package:orland_sports/View/Widgets/SummaryCard.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_form_controller.dart';
import 'package:orland_sports/enums/match_status.dart' as enums;

class ReviewSummary extends StatelessWidget {
  final Future<bool> Function() onConfirm;

  const ReviewSummary({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final RxBool isProcessing = false.obs;
    final RxBool hasBalls = false.obs; // Equipment Rule

    // ── Resolve real club/court name from MatchFormController ──────────────────
    final matchCtrl = Get.find<MatchFormController>();

    final String locationLabel;
    if (matchCtrl.preferredClubIds.isNotEmpty) {
      final count = matchCtrl.preferredClubIds.length;
      locationLabel = '$count club${count == 1 ? '' : 's'} seleccionado${count == 1 ? '' : 's'}';
    } else if (matchCtrl.selectedCourt.value != null) {
      locationLabel = matchCtrl.selectedCourt.value!.name;
    } else {
      locationLabel = 'Club por asignar';
    }

    final String sideSuffix = matchCtrl.selectedCourtSide.value.isNotEmpty
        ? ' · ${matchCtrl.selectedCourtSide.value}'
        : '';
    final String matchTypeName =
        matchCtrl.selectedMatchType.value == enums.MatchType.oneVsOne
            ? '1v1 · ${matchCtrl.selectedCategory.value}$sideSuffix'
            : '2v2 · ${matchCtrl.selectedCategory.value}$sideSuffix';

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
                Obx(() => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: hasBalls.value
                            ? kpurple1.withValues(alpha: 0.05)
                            : kgrey2.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasBalls.value ? kpurple1 : kgrey4,
                          width: hasBalls.value ? 1.5 : 1,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: hasBalls.value,
                        activeColor: kpurple1,
                        checkColor: kwhite,
                        onChanged: (val) => hasBalls.value = val ?? false,
                        title: Row(
                          children: [
                            Icon(Icons.sports_baseball_rounded,
                                size: 18, color: kpurple1),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Me comprometo a llevar pelotas nuevas al partido',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4, left: 26),
                          child: Text(
                            'Requisito obligatorio para confirmar el partido.',
                            style: TextStyle(fontSize: 11, color: kgrey1),
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
