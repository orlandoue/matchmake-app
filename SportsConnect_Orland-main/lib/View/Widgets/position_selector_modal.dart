import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';

/// Court-side options a player can prefer (pádel/tenis).
enum CourtSide { drive, reves, ambos }

extension CourtSideX on CourtSide {
  /// Value stored/displayed (matches the pre-existing 'Drive'/'Revés'/'Ambos').
  String get label {
    switch (this) {
      case CourtSide.drive:
        return 'Drive';
      case CourtSide.reves:
        return 'Revés';
      case CourtSide.ambos:
        return 'Ambos';
    }
  }

  String get subtitle {
    switch (this) {
      case CourtSide.drive:
        return 'Derecha';
      case CourtSide.reves:
        return 'Izquierda';
      case CourtSide.ambos:
        return 'Cualquier lado';
    }
  }

  IconData get icon {
    switch (this) {
      case CourtSide.drive:
        return Icons.arrow_forward_rounded;
      case CourtSide.reves:
        return Icons.arrow_back_rounded;
      case CourtSide.ambos:
        return Icons.swap_horiz_rounded;
    }
  }

  static CourtSide? fromLabel(String? label) {
    if (label == null) return null;
    final l = label.toLowerCase();
    if (l == 'drive') return CourtSide.drive;
    if (l == 'revés' || l == 'reves') return CourtSide.reves;
    if (l == 'ambos') return CourtSide.ambos;
    return null;
  }
}

/// Modal to pick the player's preferred court side, rendered as selectable
/// pill widgets. Palette-faithful (Pádel brand: kpurple1) — no new colors.
class PositionSelectorModal {
  static void show({
    String? current,
    required Function(String position) onPositionSelected,
  }) {
    final Rx<CourtSide> selected =
        (CourtSideX.fromLabel(current) ?? CourtSide.ambos).obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: kwhite,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                text: 'Elige tu Lado',
                size: 20,
                weight: FontWeight.bold,
                color: kblack2,
                paddingBottom: 6,
              ),
              MyText(
                text: 'Selecciona la posición en la que prefieres jugar.',
                size: 13,
                color: kgrey1,
                textAlign: TextAlign.center,
                paddingBottom: 22,
              ),
              Obx(
                () => Column(
                  children: [
                    for (final side in CourtSide.values) ...[
                      _SidePill(
                        side: side,
                        isSelected: selected.value == side,
                        onTap: () => selected.value = side,
                      ),
                      if (side != CourtSide.values.last)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: kgrey4),
                        ),
                      ),
                      child: MyText(
                        text: 'Cancelar',
                        color: kgrey1,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Get.back();
                        onPositionSelected(selected.value.label);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: kpurple1,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: MyText(
                        text: 'Confirmar',
                        color: kwhite,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single selectable pill row (icon + label + subtitle + check).
class _SidePill extends StatelessWidget {
  final CourtSide side;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidePill({
    required this.side,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Material(
        color: isSelected ? kpurple1 : kgrey2,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kwhite.withValues(alpha: 0.18)
                        : kwhite,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    side.icon,
                    size: 20,
                    color: isSelected ? kwhite : kpurple1,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: side.label,
                        size: 16,
                        weight: FontWeight.bold,
                        color: isSelected ? kwhite : kblack2,
                      ),
                      MyText(
                        text: side.subtitle,
                        size: 12,
                        color: isSelected
                            ? kwhite.withValues(alpha: 0.85)
                            : kgrey1,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected ? kwhite : kgrey5,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact badge that shows a chosen court side next to a player's name.
Widget getPositionBadge(String? position) {
  final side = CourtSideX.fromLabel(position);
  if (side == null) return const SizedBox.shrink();

  String short;
  Color color;
  switch (side) {
    case CourtSide.drive:
      short = 'DRV';
      color = kpurple1;
      break;
    case CourtSide.reves:
      short = 'REV';
      color = kteal;
      break;
    case CourtSide.ambos:
      short = 'AMB';
      color = kgrey1;
      break;
  }

  return Container(
    margin: const EdgeInsets.only(left: 8),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      short,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );
}
