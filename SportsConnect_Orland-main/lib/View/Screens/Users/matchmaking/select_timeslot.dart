import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orland_sports/View/Widgets/position_selector_modal.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/ReviewSummary.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_form_controller.dart';
import 'package:orland_sports/controllers/match_creation_controller.dart';

class SelectTimeslot extends StatefulWidget {
  SelectTimeslot({super.key});

  @override
  State<SelectTimeslot> createState() => _SelectTimeslotState();
}

class _SelectTimeslotState extends State<SelectTimeslot> {
  DateTime selectedDate = DateTime.now();
  String? selectedStartSlot;
  String? selectedEndSlot;

  // Cyber-League Palette
  final Color cyberNavy = const Color(0xFF0A192F);
  final Color cyberNeon = const Color(0xFF00FF85);
  final Color cyberNeonDim = const Color(0xFF00FF85).withOpacity(0.2);

  int get daysCount => 14; // Próximos 14 días

  String weekday(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// Generate 30-min slots from 07:00 to 00:00 (midnight)
  List<String> get timeSlots {
    final slots = <String>[];
    for (int h = 7; h < 24; h++) {
      for (int m = 0; m < 60; m += 30) {
        final hour = h % 12 == 0 ? 12 : h % 12;
        final ampm = h < 12 ? 'AM' : 'PM';
        final minuteStr = m.toString().padLeft(2, '0');
        slots.add('${hour.toString().padLeft(2, '0')}:$minuteStr $ampm');
      }
    }
    // Add 12:00 AM (midnight)
    slots.add('12:00 AM');
    return slots;
  }

  String get rangeLabel {
    if (selectedStartSlot == null) return 'Selecciona inicio';
    if (selectedEndSlot == null) return '$selectedStartSlot → ?';
    return '$selectedStartSlot → $selectedEndSlot';
  }

  @override
  Widget build(BuildContext context) {
    final slots = timeSlots;

    return Scaffold(
      backgroundColor: cyberNavy,
      appBar: simpleAppBar2(title: 'select_time_slot'.tr),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // ── Day picker ───────────────────────────────────────────────
                MyText(
                  paddingBottom: 10,
                  text: 'Selecciona el día',
                  size: 15,
                  weight: FontWeight.bold,
                  color: Colors.white,
                ),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: daysCount,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = selectedDate.year == date.year &&
                                         selectedDate.month == date.month &&
                                         selectedDate.day == date.day;
                      return GestureDetector(
                        onTap: () => setState(() => selectedDate = date),
                        child: Container(
                          width: 56,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? cyberNeon : cyberNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isSelected ? cyberNeon : Colors.white24),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                child: Text(
                                  weekday(date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? cyberNavy : Colors.white70,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              CircleAvatar(
                                backgroundColor: isSelected
                                    ? cyberNavy.withOpacity(0.1)
                                    : Colors.white12,
                                radius: 16,
                                child: Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? cyberNavy : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // ── Range label ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cyberNeonDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cyberNeon.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time_rounded, color: cyberNeon, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rangeLabel,
                          style: TextStyle(
                            color: cyberNeon,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                
                // Explanatory note about Flex-Match
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Selecciona tu rango de búsqueda (inicio y fin). Encontraremos el mejor horario dentro de este rango para tu partido de 60 minutos.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                MyText(
                  text: 'available_time_slots'.tr,
                  size: 15,
                  weight: FontWeight.bold,
                  paddingBottom: 12,
                  color: Colors.white,
                ),

                // ── Time slot grid ───────────────────────────────────────────
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: slots.asMap().entries.map((entry) {
                    final slot = entry.value;
                    final isStart = slot == selectedStartSlot;
                    final isEnd = slot == selectedEndSlot;
                    final isInRange = _isInRange(slot, slots);

                    Color bgColor = cyberNavy;
                    Color borderColor = Colors.white24;
                    Color textColor = Colors.white;

                    if (isStart || isEnd) {
                      bgColor = cyberNeon;
                      borderColor = cyberNeon;
                      textColor = cyberNavy;
                    } else if (isInRange) {
                      bgColor = cyberNeonDim;
                      borderColor = cyberNeon.withOpacity(0.5);
                      textColor = cyberNeon;
                    }

                    return GestureDetector(
                      onTap: () => _onSlotTap(slot, slots),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                MyButton(
                  onTap: _canConfirm
                      ? () => _proceedToNext()
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Selecciona un rango de hora inicio → fin'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                  buttonText: _canConfirm
                      ? 'Confirmar Rango: $rangeLabel'
                      : 'continue_text'.tr,
                  fillColor: _canConfirm ? cyberNeon : cyberNavy,
                  fontColor: _canConfirm ? cyberNavy : Colors.white,
                  outlineColor: _canConfirm ? cyberNeon : Colors.white24,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canConfirm => selectedStartSlot != null && selectedEndSlot != null;

  void _onSlotTap(String slot, List<String> slots) {
    setState(() {
      if (selectedStartSlot == null) {
        // First tap: set start
        selectedStartSlot = slot;
        selectedEndSlot = null;
      } else if (selectedEndSlot == null) {
        // Second tap: set end (must be after start)
        final startIdx = slots.indexOf(selectedStartSlot!);
        final tapIdx = slots.indexOf(slot);
        if (tapIdx > startIdx) {
          selectedEndSlot = slot;
          // Auto-advance
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _proceedToNext();
          });
        } else {
          // Restart selection
          selectedStartSlot = slot;
          selectedEndSlot = null;
        }
      } else {
        // Third tap: reset and start new selection
        selectedStartSlot = slot;
        selectedEndSlot = null;
      }
    });
  }

  void _proceedToNext() {
    if (!_canConfirm) return;
    
    final matchCtrl = Get.find<MatchFormController>();
    matchCtrl.selectedTimeSlot.value = selectedStartSlot!;
    matchCtrl.selectedEndTimeSlot.value = selectedEndSlot!;
    
    final now = DateTime.now();
    try {
       final format = DateFormat("h:mm a");
       final parsedTime = format.parse(selectedStartSlot!);
       final matchDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, parsedTime.hour, parsedTime.minute);
       
       if (matchDateTime.isBefore(now)) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('No puedes seleccionar una hora o fecha en el pasado.'),
             backgroundColor: Colors.red,
           ),
         );
         return;
       }
    } catch (e) {
       print('Error parsing time: $e');
    }

    matchCtrl.selectedDate.value = selectedDate;
    
    // PositionSelectorModal antes de avanzar al ReviewSummary
    PositionSelectorModal.show(
      onPositionSelected: (position) {
        // TODO: Save position to matchController
        Get.to(() => ReviewSummary(
              onConfirm: () async {
                final result = await MatchCreationController.instance.createOrJoinMatch();
                return result != null;
              },
            ));
      },
    );
  }

  bool _isInRange(String slot, List<String> slots) {
    if (selectedStartSlot == null || selectedEndSlot == null) return false;
    final startIdx = slots.indexOf(selectedStartSlot!);
    final endIdx = slots.indexOf(selectedEndSlot!);
    final slotIdx = slots.indexOf(slot);
    return slotIdx > startIdx && slotIdx < endIdx;
  }
}
