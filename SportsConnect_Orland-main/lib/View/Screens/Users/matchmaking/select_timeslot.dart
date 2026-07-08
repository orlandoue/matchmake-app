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
  const SelectTimeslot({super.key});

  @override
  State<SelectTimeslot> createState() => _SelectTimeslotState();
}

class _SelectTimeslotState extends State<SelectTimeslot> {
  DateTime selectedDate = DateTime.now();
  String? selectedStartSlot;
  String? selectedEndSlot;

  /// Carousel spans the next 30 days, strictly starting today.
  int get daysCount => 30;

  String weekday(DateTime date) => DateFormat('EEE').format(date);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _selectedIsToday => _isSameDay(selectedDate, DateTime.now());

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

  /// A slot is "past" only when the selected day is today and its time has
  /// already elapsed — such slots are shown disabled and can't be picked.
  bool _isPastSlot(String slot) {
    if (!_selectedIsToday) return false;
    try {
      final t = DateFormat("h:mm a").parse(slot);
      final slotDt = DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day, t.hour, t.minute);
      return slotDt.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
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
      backgroundColor: kwhite,
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
                  paddingBottom: 12,
                  text: 'Selecciona el día',
                  size: 15,
                  weight: FontWeight.bold,
                  color: kblack2,
                ),
                SizedBox(
                  height: 84,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: daysCount,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = _isSameDay(selectedDate, date);
                      final isToday = index == 0;
                      return GestureDetector(
                        onTap: () => setState(() {
                          selectedDate = date;
                          // Clear any picked range when switching day so a
                          // now-past slot can't stay selected.
                          selectedStartSlot = null;
                          selectedEndSlot = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 60,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? kpurple1 : kwhite,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? kpurple1 : kgrey4,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected ? kpurple1 : kblack2)
                                    .withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                child: Text(
                                  isToday ? 'Hoy' : weekday(date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? kwhite : kgrey1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              CircleAvatar(
                                backgroundColor: isSelected
                                    ? kwhite.withValues(alpha: 0.20)
                                    : kgrey2,
                                radius: 16,
                                child: Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? kwhite : kblack2,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kpurple1.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: kpurple1.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: kpurple1, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rangeLabel,
                          style: const TextStyle(
                            color: kpurple1,
                            fontWeight: FontWeight.w700,
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
                    color: kgrey2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kgrey4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: kpurple1, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Selecciona tu rango de búsqueda (inicio y fin). Encontraremos el mejor horario dentro de este rango para tu partido de 60 minutos.',
                          style: TextStyle(
                            fontSize: 12,
                            color: kgrey1,
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
                  color: kblack2,
                ),

                // ── Time slot grid ───────────────────────────────────────────
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: slots.map((slot) {
                    final isStart = slot == selectedStartSlot;
                    final isEnd = slot == selectedEndSlot;
                    final isInRange = _isInRange(slot, slots);
                    final isPast = _isPastSlot(slot);

                    Color bgColor = kwhite;
                    Color borderColor = kgrey4;
                    Color textColor = kblack2;
                    FontWeight weight = FontWeight.w500;

                    if (isPast) {
                      bgColor = kgrey3;
                      borderColor = kgrey4;
                      textColor = kgrey5;
                    } else if (isStart || isEnd) {
                      bgColor = kpurple1;
                      borderColor = kpurple1;
                      textColor = kwhite;
                      weight = FontWeight.bold;
                    } else if (isInRange) {
                      bgColor = kpurple1.withValues(alpha: 0.10);
                      borderColor = kpurple1.withValues(alpha: 0.4);
                      textColor = kpurple1;
                      weight = FontWeight.w600;
                    }

                    return GestureDetector(
                      onTap: isPast ? null : () => _onSlotTap(slot, slots),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                          boxShadow: (isStart || isEnd)
                              ? [
                                  BoxShadow(
                                    color: kpurple1.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : const [],
                        ),
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: weight,
                            color: textColor,
                            decoration: isPast
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
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
                              content: Text(
                                  'Selecciona un rango de hora inicio → fin'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                  buttonText: _canConfirm
                      ? 'Confirmar Rango: $rangeLabel'
                      : 'continue_text'.tr,
                  fillColor: _canConfirm ? kpurple1 : kgrey2,
                  fontColor: _canConfirm ? kwhite : kgrey1,
                  outlineColor: _canConfirm ? kpurple1 : kgrey4,
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
      final matchDateTime = DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day, parsedTime.hour, parsedTime.minute);

      if (matchDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No puedes seleccionar una hora o fecha en el pasado.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      print('Error parsing time: $e');
    }

    matchCtrl.selectedDate.value = selectedDate;

    // Confirm preferred court side before advancing to ReviewSummary,
    // pre-selecting whatever was chosen earlier in the wizard.
    PositionSelectorModal.show(
      current: matchCtrl.selectedCourtSide.value.isNotEmpty
          ? matchCtrl.selectedCourtSide.value
          : null,
      onPositionSelected: (position) {
        matchCtrl.selectedCourtSide.value = position;
        Get.to(() => ReviewSummary(
              onConfirm: () async {
                final result =
                    await MatchCreationController.instance.createOrJoinMatch();
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
