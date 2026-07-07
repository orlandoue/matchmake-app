import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/geo_filter_controller.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/models/club_model.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';

/// Step 2 of the matchmaking flow: the user picks nearby clubs.
/// No map — clean full-screen list with radius slider + club cards + confirm CTA.
class GeoFilterScreen extends StatelessWidget {
  const GeoFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final geoCtrl = Get.find<GeoFilterController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: '¿Dónde quieres jugar?',
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Radius control ─────────────────────────────────────────────────
          _RadiusSection(geoCtrl: geoCtrl),

          // ── Divider ────────────────────────────────────────────────────────
          Divider(height: 1, color: kgrey2),

          // ── Club list ──────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (geoCtrl.isLoading.value) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: kpurple1),
                      SizedBox(height: 16),
                      Text(
                        'Buscando clubes…',
                        style: TextStyle(color: kgrey1, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              if (geoCtrl.isLocating.value) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: kpurple1),
                      SizedBox(height: 12),
                      Text(
                        'Obteniendo ubicación…',
                        style: TextStyle(color: kgrey1, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              if (geoCtrl.nearbyClubs.isEmpty) {
                return _EmptyState(geoCtrl: geoCtrl);
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                itemCount: geoCtrl.nearbyClubs.length,
                itemBuilder: (context, index) {
                  final club = geoCtrl.nearbyClubs[index];
                  return Obx(() {
                    final isSelected = geoCtrl.selectedClubIds.contains(club.id);
                    return _ClubCard(
                      club: club,
                      isSelected: isSelected,
                      userLat: geoCtrl.userLat.value,
                      userLng: geoCtrl.userLng.value,
                      onTap: () => geoCtrl.toggleClubSelection(club.id),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),

      // ── Floating confirm button ─────────────────────────────────────────────
      bottomNavigationBar: _ConfirmButton(geoCtrl: geoCtrl),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Radius Section
// ─────────────────────────────────────────────────────────────────────────────

class _RadiusSection extends StatelessWidget {
  final GeoFilterController geoCtrl;
  const _RadiusSection({required this.geoCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kwhite,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPS status row
          Obx(() {
            if (geoCtrl.isLocating.value) return const SizedBox.shrink();
            return Row(
              children: [
                const Icon(Icons.location_on_rounded, color: kpurple1, size: 16),
                const SizedBox(width: 6),
                Text(
                  geoCtrl.userLat.value != -33.4569
                      ? 'Usando tu ubicación GPS'
                      : 'Ubicación aproximada (Santiago)',
                  style: const TextStyle(
                    color: kgrey1,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: geoCtrl.relocateUser,
                  child: const Icon(Icons.refresh_rounded,
                      color: kpurple1, size: 18),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),

          // Question
          const Text(
            '¿A qué distancia quieres jugar?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kblack2,
            ),
          ),
          const SizedBox(height: 8),

          // Slider + label
          Obx(() => Row(
                children: [
                  const Icon(Icons.radio_button_checked,
                      color: kgrey1, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: kpurple1,
                        inactiveTrackColor: kgrey2,
                        thumbColor: kpurple1,
                        overlayColor: kpurple1.withOpacity(0.15),
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: geoCtrl.radiusKm.value,
                        min: GeoFilterController.kMinRadius,
                        max: GeoFilterController.kMaxRadius,
                        divisions: 19,
                        onChanged: geoCtrl.onRadiusChanged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 54,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kpurple1.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kpurple1.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${geoCtrl.radiusKm.value.toStringAsFixed(0)} km',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kpurple1,
                      ),
                    ),
                  ),
                ],
              )),

          // Club count badge
          Obx(() {
            final n = geoCtrl.nearbyClubs.length;
            return Text(
              n == 0
                  ? 'No se encontraron clubes en este radio.'
                  : '$n club${n != 1 ? 's' : ''} encontrado${n != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: n == 0 ? kred : kgrey1,
                fontWeight: FontWeight.w500,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Club Card
// ─────────────────────────────────────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  final ClubModel club;
  final bool isSelected;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;

  const _ClubCard({
    required this.club,
    required this.isSelected,
    required this.userLat,
    required this.userLng,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final distLabel = club.distanceLabel(userLat, userLng);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? kpurple1.withOpacity(0.07) : kwhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kpurple1 : kgrey2,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Club icon / image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: club.imageUrl != null && club.imageUrl!.isNotEmpty
                  ? Image.network(
                      club.imageUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(isSelected),
                    )
                  : _iconBox(isSelected),
            ),
            const SizedBox(width: 14),

            // Club info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? kpurple1 : kblack2,
                    ),
                  ),
                  if (club.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      club.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: kgrey1),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.near_me_rounded,
                          size: 12, color: kpurple1),
                      const SizedBox(width: 4),
                      Text(
                        distLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kpurple1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isSelected ? kpurple1 : kwhite,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isSelected ? kpurple1 : kgrey1,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: kwhite, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(bool selected) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: selected
            ? kpurple1.withOpacity(0.12)
            : kgrey2.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.sports_tennis_rounded,
        color: selected ? kpurple1 : kgrey1,
        size: 26,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final GeoFilterController geoCtrl;
  const _EmptyState({required this.geoCtrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kpurple1.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  color: kpurple1, size: 34),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay clubes en este radio',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kblack2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Amplía el slider para ver más clubes cercanos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kgrey1, height: 1.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => geoCtrl.onRadiusChanged(
                (geoCtrl.radiusKm.value + 5.0).clamp(
                  GeoFilterController.kMinRadius,
                  GeoFilterController.kMaxRadius,
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Ampliar +5 km'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kpurple1,
                side: const BorderSide(color: kpurple1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirm Button (bottom bar)
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  final GeoFilterController geoCtrl;
  const _ConfirmButton({required this.geoCtrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Obx(() {
          final count = geoCtrl.selectedClubIds.length;
          final canConfirm = count > 0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54,
            decoration: BoxDecoration(
              color: canConfirm ? kpurple1 : kgrey2,
              borderRadius: BorderRadius.circular(14),
              boxShadow: canConfirm
                  ? [
                      BoxShadow(
                        color: kpurple1.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: canConfirm ? _handleConfirm : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: canConfirm ? kwhite : kgrey1,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      canConfirm
                          ? 'Confirmar $count recinto${count != 1 ? 's' : ''}'
                          : 'Selecciona al menos 1 club',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: canConfirm ? kwhite : kgrey1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _handleConfirm() {
    final matchCtrl = Get.find<MatchController>();
    matchCtrl.setPreferredClubs(geoCtrl.selectedClubIds.toList());
    // Return to SelectMatch — the club selection card will update reactively
    Get.back();
  }
}
