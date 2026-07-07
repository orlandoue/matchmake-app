import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/sport_controller.dart';
import 'package:orland_sports/models/sport_model.dart';

/// A horizontal scrollable list of sport filter chips
class SportsFilterBar extends StatelessWidget {
  final Function(SportModel)? onSportSelected;
  final bool showCourtCount;
  final bool multiSelect;
  final List<SportModel>? sports;
  final Map<String, int>? courtCountBySport;
  final bool loadCourtsOnSelection;
  final String allLabel;

  const SportsFilterBar({
    super.key,
    this.onSportSelected,
    this.showCourtCount = true,
    this.multiSelect = true,
    this.sports,
    this.courtCountBySport,
    this.loadCourtsOnSelection = true,
    this.allLabel = 'All',
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SportController>()
        ? Get.find<SportController>()
        : Get.put(SportController());

    return Obx(() {
      final displayedSports = sports ?? controller.activeSports;

      if (controller.isLoading.value) {
        return const SizedBox(
          height: 50,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kpurple1,
              ),
            ),
          ),
        );
      }

      if (displayedSports.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayedSports.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildAllChip(controller);
            }
            final sport = displayedSports[index - 1];
            final isSelected = multiSelect
                ? controller.isSportSelected(sport)
                : controller.selectedSport.value?.id == sport.id;
            final courtCount = courtCountBySport != null
                ? courtCountBySport![sport.id] ?? 0
                : controller.getCourtCount(sport.id);

            return SportFilterChip(
              sport: sport,
              isSelected: isSelected,
              courtCount: showCourtCount ? courtCount : null,
              onTap: () {
                if (multiSelect) {
                  controller.toggleSportSelection(
                    sport,
                    loadCourts: loadCourtsOnSelection,
                  );
                } else {
                  controller.selectSport(sport);
                }
                onSportSelected?.call(sport);
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildAllChip(SportController controller) {
    final isSelected = multiSelect
        ? controller.selectedSports.isEmpty
        : controller.selectedSport.value == null;

    return GestureDetector(
      onTap: () {
        if (multiSelect) {
          controller.clearAllSelectedSports(
            loadCourts: loadCourtsOnSelection,
          );
        } else {
          controller.clearSelection(loadCourts: loadCourtsOnSelection);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kpurple1 : kwhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? kpurple1 : kgrey2,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apps,
              size: 16,
              color: isSelected ? kwhite : kgrey1,
            ),
            const SizedBox(width: 6),
            MyText(
              text: allLabel,
              size: 13,
              weight: FontWeight.w600,
              color: isSelected ? kwhite : kblack2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual sport filter chip widget
class SportFilterChip extends StatelessWidget {
  final SportModel sport;
  final bool isSelected;
  final int? courtCount;
  final VoidCallback onTap;

  const SportFilterChip({
    super.key,
    required this.sport,
    required this.isSelected,
    this.courtCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? sport.color : kwhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? sport.color : kgrey2,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: sport.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sport.icon,
              size: 16,
              color: isSelected ? kwhite : sport.color,
            ),
            const SizedBox(width: 6),
            MyText(
              text: sport.name,
              size: 13,
              weight: FontWeight.w600,
              color: isSelected ? kwhite : kblack2,
            ),
            if (courtCount != null && courtCount! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? kwhite.withOpacity(0.2)
                      : sport.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: MyText(
                  text: '$courtCount',
                  size: 11,
                  weight: FontWeight.w600,
                  color: isSelected ? kwhite : sport.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A grid view of sports for selection (used in filters/bottom sheets)
class SportsSelectionGrid extends StatelessWidget {
  final List<SportModel> sports;
  final List<SportModel> selectedSports;
  final Function(SportModel) onSportToggle;
  final int crossAxisCount;

  const SportsSelectionGrid({
    super.key,
    required this.sports,
    required this.selectedSports,
    required this.onSportToggle,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: sports.length,
      itemBuilder: (context, index) {
        final sport = sports[index];
        final isSelected = selectedSports.any(
          (selectedSport) => selectedSport.id == sport.id,
        );

        return GestureDetector(
          onTap: () => onSportToggle(sport),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? sport.color.withOpacity(0.15)
                  : kgrey2.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? sport.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sport.icon,
                  size: 16,
                  color: isSelected ? sport.color : kgrey1,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: MyText(
                    text: sport.name,
                    size: 12,
                    weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? sport.color : kblack2,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact inline display of sports for a court
class CourtSportsDisplay extends StatelessWidget {
  final List<SportModel> sports;
  final int maxDisplay;
  final double iconSize;
  final double fontSize;

  const CourtSportsDisplay({
    super.key,
    required this.sports,
    this.maxDisplay = 3,
    this.iconSize = 14,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    if (sports.isEmpty) {
      return const SizedBox.shrink();
    }

    final displaySports = sports.take(maxDisplay).toList();
    final remainingCount = sports.length - maxDisplay;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displaySports.map((sport) => _buildMiniChip(sport)),
        if (remainingCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: kgrey2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: MyText(
              text: '+$remainingCount',
              size: fontSize,
              color: kgrey1,
              weight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildMiniChip(SportModel sport) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: sport.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sport.icon, size: iconSize, color: sport.color),
          const SizedBox(width: 4),
          MyText(
            text: sport.name,
            size: fontSize,
            color: sport.color,
            weight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}
