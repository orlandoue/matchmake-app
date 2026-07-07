import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/History/Ranking.dart';
import 'package:orland_sports/View/Screens/Users/History/history_matches_screen.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/player_match_detail_screen.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/ExpandedRow.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/controllers/profile_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/models/match_model.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// History Screen
///
/// Reactive data flow (zero StatefulWidget / setState):
///
///   profileController.selectedSportId   (RxString — UUID)
///     ↕ tapping a pill
///     → profileController.currentSportRanking  (derived getter)
///       → Obx() rebuilds rank card + LP bar + stats counters
///
/// Sport pills are derived from profileController.userSports, which is itself
/// derived from userRankings — it never queries the global `sports` table.
/// ─────────────────────────────────────────────────────────────────────────────
class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController   = Get.find<MatchController>();
    final profileController = Get.find<ProfileController>();
    final currentUserId     = matchController.currentUserId;

    // Trigger a fetch if the list is empty (e.g. first load of the tab).
    if (profileController.userRankings.isEmpty &&
        !profileController.isLoadingRankings.value) {
      profileController.fetchRealUserRankings();
    }

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'history'.tr,
        haveBackButton: false,
        centerTitle: false,
      ),
      body: Obx(() {
        // ── Loading guard ────────────────────────────────────────────────────
        if (matchController.isLoading.value ||
            profileController.isLoadingRankings.value) {
          return const Center(
              child: CircularProgressIndicator(color: kpurple1));
        }

        // ── Match aggregates (sport-agnostic) ────────────────────────────────
        final completedMatches  = matchController.historyMatches;
        final totalMatchesCount = matchController.completedMatches.length;
        final wonMatches        = matchController.wonMatches.length;
        final lostMatches       = matchController.lostMatches.length;
        final double winRate    = totalMatchesCount > 0 ? (wonMatches / totalMatchesCount * 100) : 0.0;

        // ── Sport-specific ranking (reactive) ────────────────────────────────
        // currentSportRanking reads selectedSportId (RxString) →
        // any Obx reading this getter rebuilds automatically on pill tap.
        final ranking   = profileController.currentSportRanking;
        final tier      = ranking?.tier             ?? 'Bronce';
        final division  = ranking?.division         ?? 3;
        final lp        = ranking?.lp               ?? 0;
        final tierColor = ranking?.leagueData.color ?? const Color(0xFFCD7F32);

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              matchController.loadPlayerMatches(),
              profileController.fetchRealUserRankings(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              // ── Title ──────────────────────────────────────────────────────
              MyText(
                text: 'my_rank'.tr,
                weight: FontWeight.bold,
                size: 20,
                color: kblack2,
                paddingBottom: 12,
              ),

              // ── Sport Selector Pills ────────────────────────────────────────
              // Shows ONLY sports where THIS user has a user_rankings row.
              // userSports is keyed by sport UUID → no string-matching bugs.
              if (profileController.userSports.isNotEmpty)
                _SportSelectorBar(profileController: profileController),
              const SizedBox(height: 14),

              // ── Rank Card (fully reactive via Obx parent) ─────────────────
              GestureDetector(
                onTap: () => Get.to(() => Ranking()),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E2024), // Dark metallic base
                        Color(0xFF141518),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: tierColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: Row(
                    children: [
                      // Circular Progress for LP
                      SizedBox(
                        width: 75,
                        height: 75,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: (lp / 100).clamp(0.0, 1.0),
                              strokeWidth: 6,
                              backgroundColor: kwhite.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                            ),
                            Center(
                              child: CommonImageView(
                                imagePath: _rankIcon(tier),
                                width: 38,
                                height: 38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
                              text: 'current_rank'.tr,
                              weight: FontWeight.w500,
                              size: 13,
                              color: kwhite.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: MyText(
                                text: '$tier $division',
                                weight: FontWeight.w900,
                                size: 28,
                                color: tierColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                              ),
                              child: MyText(
                                text: '$lp / 100 LP',
                                weight: FontWeight.bold,
                                size: 12,
                                color: kwhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: tierColor.withValues(alpha: 0.8), size: 28),
                    ],
                  ),
                ),
              ),

              // ── Season Rankings header ──────────────────────────────────────
              const SizedBox(height: 20),
              ExpandedRow(
                text1: 'season_rankings'.tr,
                text2: 'view'.tr,
                color2: kpurple1,
                weight1: FontWeight.bold,
                size1: 20,
                size2: 14,
                weight2: FontWeight.bold,
                ontap2: () => Get.to(() => Ranking()),
              ),

              // ── Stats grid ─────────────────────────────────────────────────
              MyText(
                paddingTop: 20,
                text: 'statistics'.tr,
                weight: FontWeight.bold,
                size: 20,
                color: kblack2,
                paddingBottom: 15,
              ),
              Row(
                children: [
                  Expanded(
                    child: HistoryColoredCards(
                      title: 'total_matches'.tr,
                      subTitle: '$totalMatchesCount',
                      iconData: Icons.sports_tennis,
                      baseColor: kpurple1,
                      ontap: () => Get.to(() => const HistoryMatchesScreen(
                          filterType: HistoryFilterType.totalMatches)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HistoryColoredCards(
                      title: 'win_rate'.tr,
                      subTitle: '${winRate.toStringAsFixed(1)}%',
                      iconData: Icons.pie_chart_outline,
                      baseColor: const Color(0xFFF59E0B), // Amber/Gold
                      ontap: () {}, // Decorative
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: HistoryColoredCards(
                      title: 'win'.tr,
                      subTitle: '$wonMatches',
                      iconData: Icons.emoji_events_outlined,
                      baseColor: const Color(0xFF10B981), // Emerald
                      ontap: () => Get.to(() => const HistoryMatchesScreen(
                          filterType: HistoryFilterType.won)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HistoryColoredCards(
                      title: 'lose'.tr,
                      subTitle: '$lostMatches',
                      iconData: Icons.thumb_down_alt_outlined,
                      baseColor: const Color(0xFFEF4444), // Red
                      ontap: () => Get.to(() => const HistoryMatchesScreen(
                          filterType: HistoryFilterType.lost)),
                    ),
                  ),
                ],
              ),

              // ── Recent matches ─────────────────────────────────────────────
              MyText(
                paddingTop: 20,
                text: 'recent_matches'.tr,
                weight: FontWeight.bold,
                size: 16,
                color: kblack2,
                paddingBottom: 15,
              ),
              if (completedMatches.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 64, color: kgrey1),
                        const SizedBox(height: 16),
                        MyText(
                            text: 'no_match_history'.tr,
                            size: 16,
                            color: kgrey1),
                        const SizedBox(height: 8),
                        MyText(
                            text: 'completed_matches_appear_here'.tr,
                            size: 14,
                            color: kgrey1),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: completedMatches.length,
                  itemBuilder: (_, i) => _HistoryMatchCard(
                    match: completedMatches[i],
                    currentUserId: currentUserId,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _rankIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'challenger':
      case 'diamante':
        return Assets.imagesDiamond;
      case 'oro':
        return Assets.imagesGold;
      default:
        return Assets.imagesTropy;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sport Selector Bar
//
// • Reads profileController.userSports → ({id, name}) records derived from the
//   user's own user_rankings rows. NEVER queries the sports catalogue table.
// • Tapping a pill writes profileController.selectedSportId (RxString UUID).
// • Obx inside the bar re-highlights the active pill automatically.
// ─────────────────────────────────────────────────────────────────────────────
class _SportSelectorBar extends StatelessWidget {
  final ProfileController profileController;
  const _SportSelectorBar({required this.profileController});

  IconData _icon(String name) {
    final n = name.toLowerCase();
    if (n.contains('padel') || n.contains('pádel') ||
        n.contains('tenis') || n.contains('tennis') ||
        n.contains('pickle')) return Icons.sports_tennis;
    if (n.contains('futbol') || n.contains('soccer'))
      return Icons.sports_soccer;
    if (n.contains('basket'))  return Icons.sports_basketball;
    if (n.contains('volley'))  return Icons.sports_volleyball;
    return Icons.sports;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sports     = profileController.userSports;
      final selectedId = profileController.selectedSportId.value;

      if (sports.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: sports.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final sport      = sports[i];
            final isSelected = sport.id == selectedId;

            return GestureDetector(
              // Write UUID, not name — avoids collisions if two sports share a name
              onTap: () =>
                  profileController.selectedSportId.value = sport.id,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? kpurple1 : kwhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? kpurple1 : kgrey2,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(sport.name),
                      size: 14,
                      color: isSelected ? kwhite : kgrey1,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sport.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? kwhite : kgrey1,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Match history card
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryMatchCard extends StatelessWidget {
  final MatchModel match;
  final String? currentUserId;

  const _HistoryMatchCard({
    required this.match,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isWinner    = match.winnerId == currentUserId;
    final isCancelled = match.status == MatchStatus.cancelled;

    return GestureDetector(
      onTap: () => Get.to(() => PlayerMatchDetailScreen(match: match)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kwhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCancelled
                ? kgrey2
                : (isWinner
                    ? kpurple1.withValues(alpha: 0.3)
                    : kred.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: kgrey1.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? kgrey2
                        : (isWinner
                            ? kpurple1.withValues(alpha: 0.1)
                            : kred.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCancelled
                        ? Icons.cancel_outlined
                        : (isWinner
                            ? Icons.emoji_events
                            : Icons.sports_tennis),
                    color: isCancelled
                        ? kgrey1
                        : (isWinner ? kpurple1 : kred),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text:
                            '${match.player1Name} vs ${match.player2Name}',
                        size: 15,
                        weight: FontWeight.w600,
                        color: kblack2,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      MyText(
                        text: match.matchType.displayName,
                        size: 12,
                        color: kgrey1,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? kgrey2
                        : (isWinner ? kpurple1 : kred),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: MyText(
                    text: isCancelled
                        ? 'Cancelled'
                        : (isWinner ? 'Won' : 'Lost'),
                    size: 12,
                    color: isCancelled ? kgrey1 : kwhite,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: kgrey1),
                const SizedBox(width: 4),
                Expanded(
                  child: MyText(
                    text: match.court?.name ?? 'Court',
                    size: 12,
                    color: kgrey1,
                    maxLines: 1,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 14, color: kgrey1),
                const SizedBox(width: 4),
                Flexible(
                  child: MyText(
                    text: match.formattedDate,
                    size: 12,
                    color: kgrey1,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coloured stat card (Modern Redesign)
// ─────────────────────────────────────────────────────────────────────────────
class HistoryColoredCards extends StatelessWidget {
  final Color baseColor;
  final String title;
  final String subTitle;
  final IconData iconData;
  final VoidCallback ontap;

  const HistoryColoredCards({
    super.key,
    required this.baseColor,
    required this.title,
    required this.subTitle,
    required this.iconData,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        decoration: BoxDecoration(
          color: kwhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: baseColor.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: baseColor, size: 20),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: kgrey1.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MyText(
                text: title,
                weight: FontWeight.w600,
                size: 14,
                color: kgrey1,
              ),
            ),
            const SizedBox(height: 4),
            MyText(
              text: subTitle,
              weight: FontWeight.bold,
              size: 22,
              color: kblack2,
            ),
          ],
        ),
      ),
    );
  }
}
