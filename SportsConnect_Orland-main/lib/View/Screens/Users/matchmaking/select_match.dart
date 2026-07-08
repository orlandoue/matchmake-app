import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:orland_sports/bindings/bindings.dart';
import 'package:orland_sports/View/BottomNavBars/BottomNavbar.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/geo_filter_screen.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/select_timeslot.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_form_controller.dart';
import 'package:orland_sports/controllers/match_creation_controller.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/match_model.dart';

class SelectMatch extends StatelessWidget {
  final CourtModel? preSelectedCourt;

  const SelectMatch({super.key, this.preSelectedCourt});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<MatchFormController>();

    // If a court is pre-selected, set it
    if (preSelectedCourt != null) {
      matchController.selectedCourt.value = preSelectedCourt;
    }

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'select_match'.tr,
        haveBackButton: true,
        centerTitle: false,
        actions: [
          ticketcount(),
          const SizedBox(width: 13),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Sport Selection — chips built dynamically from DB names
                // so 'selectedSport' always matches the key in sportUUIDMap.
                MyText(
                  text: 'Deporte',
                  size: 16,
                  weight: FontWeight.bold,
                  color: kblack2,
                  paddingBottom: 12,
                ),
                Obx(() {
                  final sportNames = matchController.sportUUIDMap.keys.toList();
                  // If map not yet loaded fall back to known names
                  final displayNames = sportNames.isNotEmpty
                      ? sportNames
                      : ['Tenis', 'Pádel'];

                  // Emoji helper
                  String _emoji(String name) {
                    final n = name.toLowerCase();
                    if (n.contains('tenis') || n.contains('tennis')) return '🎾';
                    if (n.contains('padel') || n.contains('pádel') || n.contains('padel')) return '🏸';
                    if (n.contains('futbol') || n.contains('fútbol') || n.contains('soccer')) return '⚽';
                    if (n.contains('basket')) return '🏀';
                    if (n.contains('volei') || n.contains('voley')) return '🏐';
                    return '🏅';
                  }

                  // Auto-select first sport if nothing is selected yet
                  if (matchController.selectedSport.value.isEmpty && displayNames.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      matchController.selectedSport.value = displayNames.first;
                    });
                  }

                  return Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: displayNames.map((name) {
                      final isSelected = matchController.selectedSport.value == name;
                      return ChoiceChip(
                        label: Text('$name ${_emoji(name)}'),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) matchController.selectedSport.value = name;
                        },
                        selectedColor: kpurple1.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? kpurple1 : kblack2,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 24),

                // Match Type Selection
                MyText(
                  text: 'match_type_label'.tr,
                  size: 16,
                  weight: FontWeight.bold,
                  color: kblack2,
                  paddingBottom: 12,
                ),
                Obx(() {
                   // Normalize accents so 'Padel' == 'Pádel'
                   final _normSport = matchController.selectedSport.value
                       .toLowerCase()
                       .replaceAll(RegExp(r'[áàäâã]'), 'a')
                       .replaceAll(RegExp(r'[éèëê]'), 'e')
                       .replaceAll(RegExp(r'[íìïî]'), 'i')
                       .replaceAll(RegExp(r'[óòöôõ]'), 'o')
                       .replaceAll(RegExp(r'[úùüû]'), 'u');
                   final isPadel = _normSport.contains('padel');
                   if (isPadel) {
                      // Automagically set it to 2v2 if it was 1v1
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                         if (matchController.selectedMatchType.value == MatchType.oneVsOne) {
                            matchController.selectedMatchType.value = MatchType.twoVsTwo;
                         }
                      });
                      return Opacity(
                         opacity: 0.5,
                         child: _MatchTypeCard(
                            type: MatchType.oneVsOne,
                            label: 'one_vs_one'.tr,
                            description: 'No disponible para Pádel',
                            isSelected: false,
                            onTap: () {
                               CustomToast.instance.showWarningToast(title: 'Modo no válido', message: 'El Pádel se juega únicamente en modalidad 2v2.');
                            },
                         ),
                      );
                   }
                   
                   return _MatchTypeCard(
                      type: MatchType.oneVsOne,
                      label: 'one_vs_one'.tr,
                      description: 'single_player_match'.tr,
                      isSelected: matchController.selectedMatchType.value == MatchType.oneVsOne,
                      onTap: () {
                         matchController.selectedMatchType.value = MatchType.oneVsOne;
                         matchController.hasPartner.value = false;
                      },
                   );
                }),
                Obx(() => _MatchTypeCard(
                      type: MatchType.twoVsTwo,
                      label: 'two_vs_two'.tr,
                      description: 'team_doubles_match'.tr,
                      isSelected: matchController.selectedMatchType.value == MatchType.twoVsTwo,
                      onTap: () {
                         matchController.selectedMatchType.value = MatchType.twoVsTwo;
                         matchController.hasPartner.value = false;
                      },
                    )),

                // Partner Options
                Obx(() {
                   if (matchController.selectedMatchType.value == MatchType.twoVsTwo) {
                      return Column(
                         crossAxisAlignment: CrossAxisAlignment.stretch,
                         children: [
                            const SizedBox(height: 10),
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                               decoration: BoxDecoration(
                                  color: kpurple1.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kgrey2),
                               ),
                               child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                     Row(
                                        children: [
                                           Checkbox(
                                              value: matchController.hasPartner.value,
                                              activeColor: kpurple1,
                                              onChanged: (val) {
                                                 matchController.hasPartner.value = val ?? false;
                                                 if (!(val ?? false)) {
                                                    matchController.partnerEmail.value = '';
                                                 }
                                              },
                                           ),
                                           Expanded(child: MyText(text: 'Tengo dupla (Invitar por correo)', size: 14, weight: FontWeight.w600, color: kblack2)),
                                        ],
                                     ),
                                     if (matchController.hasPartner.value)
                                        Padding(
                                           padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                                           child: TextFormField(
                                              style: TextStyle(fontSize: 14),
                                              initialValue: matchController.partnerEmail.value,
                                              onChanged: (val) => matchController.partnerEmail.value = val,
                                              keyboardType: TextInputType.emailAddress,
                                              decoration: InputDecoration(
                                                 hintText: 'ejemplo@correo.com',
                                                 filled: true,
                                                 fillColor: kwhite,
                                                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kgrey2)),
                                                 enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kgrey2)),
                                                 focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kpurple1)),
                                              ),
                                           ),
                                        ),
                                  ],
                               ),
                            ),
                            const SizedBox(height: 10),
                         ],
                      );
                   }
                   return const SizedBox.shrink();
                }),

                const SizedBox(height: 24),

                // Category Selection
                MyText(
                  text: 'Categoría',
                  size: 16,
                  weight: FontWeight.bold,
                  color: kblack2,
                  paddingBottom: 12,
                ),
                Obx(() {
                  final is1v1 = matchController.selectedMatchType.value == MatchType.oneVsOne;
                  return Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text('Masculino'),
                          selected: matchController.selectedCategory.value == 'Masculino',
                          onSelected: (bool selected) {
                            if (selected) matchController.selectedCategory.value = 'Masculino';
                          },
                          selectedColor: kpurple1.withOpacity(0.2),
                          labelStyle: TextStyle(
                              color: matchController.selectedCategory.value == 'Masculino'
                                  ? kpurple1
                                  : kblack2,
                                fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Text('Femenino'),
                          selected: matchController.selectedCategory.value == 'Femenino',
                          onSelected: (bool selected) {
                            if (selected) matchController.selectedCategory.value = 'Femenino';
                          },
                          selectedColor: kpurple1.withOpacity(0.2),
                          labelStyle: TextStyle(
                              color: matchController.selectedCategory.value == 'Femenino'
                                  ? kpurple1
                                  : kblack2,
                                fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!is1v1) const SizedBox(width: 8),
                      if (!is1v1)
                        Expanded(
                          child: ChoiceChip(
                            label: Text('Mixto'),
                            selected: matchController.selectedCategory.value == 'Mixto',
                            onSelected: (bool selected) {
                              if (selected) matchController.selectedCategory.value = 'Mixto';
                            },
                            selectedColor: kpurple1.withOpacity(0.2),
                            labelStyle: TextStyle(
                                color: matchController.selectedCategory.value == 'Mixto'
                                    ? kpurple1
                                    : kblack2,
                                  fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  );
                }),

                const SizedBox(height: 24),

                // Match Mode Selection
                MyText(
                  text: 'match_mode'.tr,
                  size: 16,
                  weight: FontWeight.bold,
                  color: kblack2,
                  paddingBottom: 12,
                ),
                Obx(() => _MatchModeCard(
                      mode: MatchMode.competitive,
                      label: 'competitive'.tr,
                      description:
                          'competitive_description'.tr,
                      icon: Icons.emoji_events,
                      isSelected: matchController.selectedMatchMode.value ==
                          MatchMode.competitive,
                      onTap: () => matchController.selectedMatchMode.value =
                          MatchMode.competitive,
                    )),
                Obx(() => _MatchModeCard(
                      mode: MatchMode.friendly,
                      label: 'friendly'.tr,
                      description:
                          'friendly_description'.tr,
                      icon: Icons.people,
                      isSelected: matchController.selectedMatchMode.value ==
                          MatchMode.friendly,
                      onTap: () => matchController.selectedMatchMode.value =
                          MatchMode.friendly,
                    )),

                const SizedBox(height: 20),
                // Court / Club Selection
                Obx(() {
                  final isGeoFlow = matchController.preferredClubIds.isNotEmpty;

                  if (isGeoFlow) {
                    // GEO FLOW: show selected clubs (read-only info card)
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MyText(
                              text: 'Clubes preferidos',
                              size: 16,
                              weight: FontWeight.bold,
                              color: kblack2,
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Get.to(() => const GeoFilterScreen());
                              },
                              icon: const Icon(Icons.edit_location_alt_rounded,
                                  size: 16, color: kpurple1),
                              label: MyText(
                                text: 'Cambiar',
                                size: 13,
                                color: kpurple1,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kpurple1.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: kpurple1.withOpacity(0.3), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      color: kpurple1, size: 18),
                                  const SizedBox(width: 6),
                                  MyText(
                                    text:
                                        '${matchController.preferredClubIds.length} club(s) seleccionado(s)',
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: kpurple1,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              MyText(
                                text:
                                    'El admin del club asignará la cancha una vez confirmado el partido.',
                                size: 12,
                                color: kgrey1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }

                  // LEGACY FLOW: court picker
                  if (preSelectedCourt != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: 'selected_court'.tr,
                          size: 16,
                          weight: FontWeight.bold,
                          color: kblack2,
                          paddingBottom: 12,
                        ),
                        _SelectedCourtCard(
                          court: preSelectedCourt!,
                          onTap: null,
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyText(
                            text: 'Club seleccionado',
                            size: 16,
                            weight: FontWeight.bold,
                            color: kblack2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      matchController.selectedCourt.value != null
                          ? _SelectedCourtCard(
                              court: matchController.selectedCourt.value!,
                              onTap: () =>
                                  Get.to(() => const GeoFilterScreen()),
                            )
                          : GestureDetector(
                              onTap: () => Get.to(() => const GeoFilterScreen()),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: kpurple1.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kpurple1.withOpacity(0.4), width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: kpurple1),
                                    const SizedBox(width: 8),
                                    MyText(
                                      text: 'Buscar club por ubicación',
                                      size: 14,
                                      color: kpurple1,
                                      weight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                    ],
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Next Button — goes to SelectTimeslot (Paso 3)
          Padding(
            padding: const EdgeInsets.all(20),
            child: MyButton(
              onTap: () => Get.to(() => SelectTimeslot()),
              buttonText: 'next'.tr,
              fillColor: kpurple1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchTypeCard extends StatelessWidget {
  final MatchType type;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _MatchTypeCard({
    required this.type,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kpurple1 : kwhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kpurple1 : kgrey2,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? kwhite.withOpacity(0.2)
                    : kpurple1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: MyText(
                  text: type == MatchType.oneVsOne ? '1v1' : '2v2',
                  size: 16,
                  weight: FontWeight.bold,
                  color: isSelected ? kwhite : kpurple1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: label,
                    size: 16,
                    weight: FontWeight.w600,
                    color: isSelected ? kwhite : kblack2,
                  ),
                  MyText(
                    text: description,
                    size: 12,
                    color: isSelected ? kwhite.withOpacity(0.8) : kgrey1,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: kwhite, size: 24),
          ],
        ),
      ),
    );
  }
}

class _MatchModeCard extends StatelessWidget {
  final MatchMode mode;
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MatchModeCard({
    required this.mode,
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kpurple1.withOpacity(0.1) : kwhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kpurple1 : kgrey2,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? kpurple1 : kgrey1, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: label,
                    size: 14,
                    weight: FontWeight.w600,
                    color: isSelected ? kpurple1 : kblack2,
                  ),
                  MyText(
                    text: description,
                    size: 12,
                    color: kgrey1,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: kpurple1, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SelectedCourtCard extends StatelessWidget {
  final CourtModel court;
  final VoidCallback? onTap;

  const _SelectedCourtCard({
    required this.court,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kpurple1.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kpurple1, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kpurple1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: court.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        court.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.sports_tennis, color: kpurple1),
                      ),
                    )
                  : const Icon(Icons.sports_tennis, color: kpurple1, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: court.name,
                    size: 16,
                    weight: FontWeight.w600,
                    color: kblack2,
                  ),
                  if (court.address != null)
                    MyText(
                      text: court.address!,
                      size: 12,
                      color: kgrey1,
                      maxLines: 1,
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: court.isIndoor
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: MyText(
                      text: court.isIndoor ? 'indoor'.tr : 'outdoor'.tr,
                      size: 10,
                      color: court.isIndoor ? Colors.blue : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: kgrey1),
          ],
        ),
      ),
    );
  }
}

// Time Slot Selection Screen
class SelectTimeslotScreen extends StatelessWidget {
  const SelectTimeslotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<MatchFormController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'select_date_time'.tr,
        haveBackButton: true,
        centerTitle: false,
        actions: [
          ticketcount(),
          const SizedBox(width: 13),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Date Selection
                MyText(
                  text: 'select_date'.tr,
                  size: 16,
                  weight: FontWeight.bold,
                  color: kblack2,
                  paddingBottom: 12,
                ),
                _DateSelector(controller: matchController),

                const SizedBox(height: 24),

                // Time Slot Selection - Start Time
                MyText(
                  text: 'start_time'.tr,
                  size: 16,
                  weight: FontWeight.bold,
                  color: kblack2,
                  paddingBottom: 12,
                ),
                _TimeSlotGrid(
                  controller: matchController,
                  isStartTime: true,
                ),

                const SizedBox(height: 24),

                // Time Slot Selection - End Time
                MyText(
                  text: 'end_time'.tr,
                  size: 16,
                  weight: FontWeight.bold,
                  color: kblack2,
                  paddingBottom: 12,
                ),
                _TimeSlotGrid(
                  controller: matchController,
                  isStartTime: false,
                ),
              ],
            ),
          ),

          // Next Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() => MyButton(
                  onTap: matchController.selectedTimeSlot.value.isNotEmpty &&
                          matchController.selectedEndTimeSlot.value.isNotEmpty
                      ? () => Get.to(() => const ReviewMatchScreen())
                      : () {
                          CustomToast.instance.showWarningToast(
                            title: 'select_time_range'.tr,
                            message: 'please_select_both_times'.tr,
                          );
                        },
                  buttonText: 'next'.tr,
                  fillColor: matchController
                              .selectedTimeSlot.value.isNotEmpty &&
                          matchController.selectedEndTimeSlot.value.isNotEmpty
                      ? kpurple1
                      : kgrey1,
                )),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final MatchFormController controller;

  const _DateSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(14, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final dayName = _getDayName(date.weekday);
          final isToday = index == 0;

          return Obx(() {
            final isSelected =
                controller.selectedDate.value.year == date.year &&
                    controller.selectedDate.value.month == date.month &&
                    controller.selectedDate.value.day == date.day;

            return GestureDetector(
              onTap: () => controller.selectedDate.value = date,
              child: Container(
                width: 65,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isSelected ? kpurple1 : kwhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kpurple1 : kgrey2,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyText(
                      text: isToday ? 'today'.tr : dayName,
                      size: 11,
                      color: isSelected ? kwhite.withOpacity(0.8) : kgrey1,
                    ),
                    const SizedBox(height: 4),
                    MyText(
                      text: '${date.day}',
                      size: 22,
                      weight: FontWeight.bold,
                      color: isSelected ? kwhite : kblack2,
                    ),
                    MyText(
                      text: _getMonthName(date.month),
                      size: 11,
                      color: isSelected ? kwhite.withOpacity(0.8) : kgrey1,
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class _TimeSlotGrid extends StatelessWidget {
  final MatchFormController controller;
  final bool isStartTime;

  const _TimeSlotGrid({
    required this.controller,
    this.isStartTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final timeSlots = [
      '08:00 AM',
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '01:00 PM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM',
      '05:00 PM',
      '06:00 PM',
      '07:00 PM',
      '08:00 PM',
      '09:00 PM',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];

        return Obx(() {
          final selectedValue = isStartTime
              ? controller.selectedTimeSlot.value
              : controller.selectedEndTimeSlot.value;
          final isSelected = selectedValue == slot;

          // For end time, disable slots at or before the start time
          bool isDisabled = false;
          if (!isStartTime && controller.selectedTimeSlot.value.isNotEmpty) {
            final startIndex =
                timeSlots.indexOf(controller.selectedTimeSlot.value);
            if (startIndex >= 0 && index <= startIndex) {
              isDisabled = true;
            }
          }

          return GestureDetector(
            onTap: isDisabled
                ? null
                : () {
                    if (isStartTime) {
                      controller.selectedTimeSlot.value = slot;
                      // Clear end time if it's now invalid
                      if (controller.selectedEndTimeSlot.value.isNotEmpty) {
                        final endIndex = timeSlots
                            .indexOf(controller.selectedEndTimeSlot.value);
                        if (endIndex <= index) {
                          controller.selectedEndTimeSlot.value = '';
                        }
                      }
                    } else {
                      controller.selectedEndTimeSlot.value = slot;
                    }
                  },
            child: Container(
              decoration: BoxDecoration(
                color: isDisabled
                    ? kgrey2.withOpacity(0.5)
                    : isSelected
                        ? kpurple1
                        : kwhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDisabled
                      ? kgrey2
                      : isSelected
                          ? kpurple1
                          : kgrey2,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: MyText(
                  text: slot,
                  size: 12,
                  weight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isDisabled
                      ? kgrey1.withOpacity(0.5)
                      : isSelected
                          ? kwhite
                          : kblack2,
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

// Review Match Screen
class ReviewMatchScreen extends StatelessWidget {
  const ReviewMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<MatchFormController>();
    final court = matchController.selectedCourt.value;

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'review_confirm'.tr,
        haveBackButton: true,
        centerTitle: false,
        actions: [
          ticketcount(),
          const SizedBox(width: 13),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Match Summary Card using summaryCard widget style
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: kwhite,
                    border: Border.all(color: kgrey2),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Column(
                    children: [
                      _ExpandedRowItem(
                        text1: 'match_type_label'.tr,
                        text2:
                            matchController.selectedMatchType.value.displayName,
                      ),
                      const SizedBox(height: 20),
                      _ExpandedRowItem(
                        text1: 'match_mode'.tr,
                        text2:
                            matchController.selectedMatchMode.value.displayName,
                      ),
                      const SizedBox(height: 20),
                      _ExpandedRowItem(
                        text1: 'court'.tr,
                        text2: court?.name ?? 'not_selected'.tr,
                      ),
                      const SizedBox(height: 20),
                      _ExpandedRowItem(
                        text1: 'date'.tr,
                        text2: _formatDate(matchController.selectedDate.value),
                      ),
                      const SizedBox(height: 20),
                      _ExpandedRowItem(
                        text1: 'time'.tr,
                        text2:
                            '${matchController.selectedTimeSlot.value} - ${matchController.selectedEndTimeSlot.value}',
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: kgrey2),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyText(
                            text: 'total'.tr,
                            color: kblack2,
                            weight: FontWeight.bold,
                            size: 16,
                          ),
                          Row(
                            children: [
                              Image.asset(
                                Assets.imagesTicket,
                                width: 22,
                                height: 22,
                              ),
                              MyText(
                                text: 'x1',
                                color: kpurple1,
                                weight: FontWeight.bold,
                                size: 16,
                                paddingLeft: 6,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MyText(
                          text: matchController.selectedMatchMode.value ==
                                  MatchMode.competitive
                              ? 'competitive_info'.tr
                              : 'friendly_info'.tr,
                          size: 13,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(
              () => MatchCreationController.instance.isSearchingMatch.value
                  ? const Center(
                      child: CircularProgressIndicator(color: kpurple1))
                  : MyButton(
                      onTap: () async {
                        final match = await MatchCreationController.instance.createOrJoinMatch();
                        if (match != null) {
                          Get.offAll(() => MatchWaitingScreen(match: match));
                        }
                      },
                      buttonText: 'confirm_find_match'.tr,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ExpandedRowItem extends StatelessWidget {
  final String text1;
  final String text2;

  const _ExpandedRowItem({
    required this.text1,
    required this.text2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(
          text: text1,
          color: kblack2,
          size: 16,
        ),
        MyText(
          text: text2,
          color: kblack2,
          size: 16,
        ),
      ],
    );
  }
}

// Match Waiting Screen
class MatchWaitingScreen extends StatelessWidget {
  final dynamic match;
  final bool isJoining;

  const MatchWaitingScreen({
    super.key,
    required this.match,
    this.isJoining = false,
  });

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<MatchFormController>();

    // Set currentMatch so realtime subscription can update it
    if (match is MatchModel) {
      PlayerMatchesController.instance.currentMatch.value = match as MatchModel;
    }

    return Scaffold(
      backgroundColor: kwhite,
      appBar:
          simpleAppBar2(title: isJoining ? 'match_joined'.tr : 'match_created_label'.tr),
      body: Obx(() {
        final currentMatch = PlayerMatchesController.instance.currentMatch.value;
        final matchStatus = currentMatch?.status ?? MatchStatus.pending;
        final isMatched = matchStatus == MatchStatus.matched ||
            matchStatus == MatchStatus.confirmed ||
            matchStatus == MatchStatus.inProgress;
        final invCode = currentMatch?.inviteCode ?? match.inviteCode;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isMatched || isJoining)
                        ? Colors.green.withOpacity(0.1)
                        : kpurple1.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (isMatched || isJoining)
                        ? Icons.check_circle
                        : Icons.hourglass_top,
                    color: (isMatched || isJoining) ? Colors.green : kpurple1,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(matchStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: MyText(
                    text: matchStatus.displayName,
                    size: 14,
                    color: kwhite,
                    weight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                MyText(
                  text: isJoining || isMatched
                      ? 'match_ready'.tr
                      : 'match_created_successfully'.tr,
                  size: 22,
                  weight: FontWeight.bold,
                  color: kblack2,
                ),
                const SizedBox(height: 12),
                MyText(
                  text: _getStatusMessage(
                    matchStatus: matchStatus,
                    isJoining: isJoining,
                    matchMode: matchController.selectedMatchMode.value,
                  ),
                  size: 14,
                  color: kgrey1,
                  textAlign: TextAlign.center,
                ),
                if (invCode != null && !isJoining && !isMatched) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: kpurple1,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        MyText(
                          text: 'invite_code_label'.tr,
                          size: 14,
                          color: kwhite.withOpacity(0.8),
                        ),
                        const SizedBox(height: 8),
                        MyText(
                          text: invCode,
                          size: 32,
                          weight: FontWeight.bold,
                          color: kwhite,
                          letterSpacing: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                            text:
                                'Join my match on Matchmake!\nUse invite code: $invCode\n\nCourt: ${currentMatch?.court?.name ?? "TBD"}\nDate: ${currentMatch?.formattedDate ?? ""}\nTime: ${currentMatch?.timeRangeDisplay ?? ""}'),
                      );
                    },
                    icon: const Icon(Icons.share, color: kpurple1),
                    label: MyText(
                        text: 'share_code_btn'.tr,
                        color: kpurple1,
                        weight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 48),
                MyButton(
                  onTap: () => Get.offAll(() => BottomNavBar(),
                      binding: PlayerBinding()),
                  buttonText: 'back_to_home'.tr,
                  fillColor: kgrey1,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _getStatusMessage({
    required MatchStatus matchStatus,
    required bool isJoining,
    required MatchMode matchMode,
  }) {
    if (isJoining || matchStatus == MatchStatus.matched) {
      return 'opponent_found_waiting'.tr;
    }
    if (matchStatus == MatchStatus.confirmed) {
      return 'match_confirmed_ready'.tr;
    }
    if (matchStatus == MatchStatus.inProgress) {
      return 'match_in_progress_msg'.tr;
    }
    if (matchMode == MatchMode.competitive) {
      return 'waiting_for_opponent_msg'.tr;
    }
    return 'match_created_share'.tr;
  }

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.waitingForOpponent:
        return Colors.orange;
      case MatchStatus.matched:
        return Colors.blue;
      case MatchStatus.confirmed:
        return Colors.teal;
      case MatchStatus.inProgress:
        return Colors.green;
      case MatchStatus.completed:
        return kpurple1;
      case MatchStatus.cancelled:
        return Colors.red;
      default:
        return kgrey1;
    }
  }
}
