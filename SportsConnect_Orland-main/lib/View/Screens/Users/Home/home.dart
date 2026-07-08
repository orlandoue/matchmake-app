import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Home/player_qr_scanner_screen.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/available_matches_screen.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/player_match_detail_screen.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/player_matches_screen.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/select_match.dart';
import 'package:orland_sports/View/Widgets/ButtonContainer.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/controllers/match_form_controller.dart';
import 'package:orland_sports/controllers/match_creation_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/match_model.dart';

class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<PlayerMatchesController>();

    // Load courts when home loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MatchFormController.instance.loadAvailableCourts();
      matchController.loadPlayerMatches();
      matchController.loadAvailableMatchesToJoin();
    });

    return Scaffold(
      backgroundColor: kwhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await MatchFormController.instance.loadAvailableCourts();
                await matchController.loadPlayerMatches();
              },
              child: ListView(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  HomeAppbarWidget(),

                  // Match Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              Get.to(() => const AvailableMatchesScreen()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: kpurple1.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kpurple1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, color: kpurple1, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: MyText(
                                    text: 'find_match'.tr,
                                    size: 14,
                                    weight: FontWeight.bold,
                                    color: kpurple1,
                                    maxLines: 1,
                                    isEllipsized: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Get.to(() => const SelectMatch()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: kpurple1,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: kwhite, size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: MyText(
                                    text: 'Jugar',
                                    size: 14,
                                    weight: FontWeight.bold,
                                    color: kwhite,
                                    maxLines: 1,
                                    isEllipsized: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Available Matches Preview
                  Obx(() {
                    if (matchController.availableMatchesToJoin.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MyText(
                                text: 'available_matches'.tr,
                                size: 16,
                                weight: FontWeight.bold,
                                color: kblack2,
                              ),
                              TextButton(
                                onPressed: () => Get.to(
                                    () => const AvailableMatchesScreen()),
                                child: MyText(
                                  text: 'view_all'.tr,
                                  size: 14,
                                  color: kpurple1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _AvailableMatchPreview(
                            count:
                                matchController.availableMatchesToJoin.length,
                          ),
                          const SizedBox(height: 15),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // Active Matches Section
                  Obx(() {
                    if (matchController.activeMatches.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MyText(
                                text: 'your_active_matches'.tr,
                                size: 16,
                                weight: FontWeight.bold,
                                color: kblack2,
                              ),
                              TextButton(
                                onPressed: () {
                                  Get.to(() => const PlayerMatchesScreen());
                                },
                                child: MyText(
                                  text: 'view_all'.tr,
                                  size: 14,
                                  color: kpurple1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...matchController.activeMatches.take(2).map(
                                (match) => _ActiveMatchCard(match: match),
                              ),
                          const SizedBox(height: 15),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // Nearby Courts Section
                  Obx(() {
                    final courtCount = MatchFormController.instance.availableCourts.length;
                    return buttonContainer(
                      text: 'courts_around_you'.trParams({'count': '$courtCount'}),
                      icon: Icons.location_on_outlined,
                      iconColor: kred,
                      bgColor: kred.withOpacity(0.05),
                      radius: 10,
                      iscenter: false,
                    );
                  }),

                  const SizedBox(height: 15),

                  // Courts List
                  Obx(() {
                    if (matchController.isLoading.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: kpurple1),
                        ),
                      );
                    }

                    if (MatchFormController.instance.availableCourts.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kgrey2.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.sports_tennis,
                                size: 48, color: kgrey1),
                            const SizedBox(height: 12),
                            MyText(
                              text: 'no_courts_available'.tr,
                              size: 14,
                              color: kgrey1,
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: 'available_courts'.tr,
                          size: 16,
                          weight: FontWeight.bold,
                          color: kblack2,
                          paddingBottom: 12,
                        ),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: MatchFormController.instance.availableCourts.length,
                            itemBuilder: (context, index) {
                              final court =
                                  MatchFormController.instance.availableCourts[index];
                              return _CourtCard(court: court);
                            },
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),

                  // Team Mode Coming Soon - Commented out
                  // Container(
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(10),
                  //     gradient: LinearGradient(
                  //       colors: [kpurple1, kpurple1.withOpacity(0.7)],
                  //       begin: Alignment.topLeft,
                  //       end: Alignment.bottomRight,
                  //     ),
                  //   ),
                  //   padding: const EdgeInsets.all(16),
                  //   child: Row(
                  //     children: [
                  //       const Icon(Icons.groups, size: 48, color: kwhite),
                  //       const SizedBox(width: 12),
                  //       Expanded(
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             MyText(
                  //               text: 'Team Mode Coming Soon!',
                  //               color: kwhite,
                  //               weight: FontWeight.bold,
                  //               size: 16,
                  //             ),
                  //             const SizedBox(height: 4),
                  //             MyText(
                  //               text:
                  //                   'Gather your companions & form your official team',
                  //               color: kwhite.withOpacity(0.9),
                  //               size: 12,
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 15),

                  // Contextual Check-in Banner
                  _CheckInBanner(),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CommonImageView(
                        imagePath: Assets.imagesGold,
                        width: 72,
                        height: 72,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Obx(() {
                          final currentUserId = matchController.currentUserId;
                          final completedMatches = matchController.playerMatches
                              .where((m) => m.status == MatchStatus.completed)
                              .toList();
                          final wonMatches = completedMatches
                              .where((m) => m.winnerId == currentUserId)
                              .length;
                          const int prizeGoal = 1500;
                          final int accumulatedPrize = wonMatches * 30;
                          final double progress =
                              (accumulatedPrize / prizeGoal).clamp(0.0, 1.0);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                text:
                                    '${'final_accumulated_prize'.tr} \$$accumulatedPrize / \$$prizeGoal',
                                color: kblack2,
                                weight: FontWeight.w600,
                                size: 13,
                                paddingBottom: 8,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: kwhite,
                                  border:
                                      Border.all(color: kpurple1, width: 1.0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    minHeight: 10,
                                    backgroundColor: kwhite,
                                    color: kpurple1,
                                    value: progress,
                                  ),
                                ),
                              ),
                              MyText(
                                paddingTop: 6,
                                text:
                                    '$wonMatches wins — ${(progress * 100).toInt()}% to the Final',
                                color: kblack2,
                                weight: FontWeight.w600,
                                size: 12,
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinByCodeDialog() {
    final codeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: MyText(
          text: 'join_match'.tr,
          size: 20,
          weight: FontWeight.bold,
          color: kblack2,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(
              text: 'enter_invite_code'.tr,
              size: 14,
              color: kgrey1,
              paddingBottom: 16,
            ),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                hintText: 'XXXXXX',
                hintStyle: TextStyle(color: kgrey1.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kgrey2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kpurple1, width: 2),
                ),
              ),
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: MyText(text: 'cancel'.tr, color: kgrey1),
          ),
          Obx(() => ElevatedButton(
                onPressed: MatchCreationController.instance.isJoiningMatch.value
                    ? null
                    : () async {
                        if (codeController.text.length == 6) {
                          final match = await MatchCreationController.instance.joinMatchByCode(
                            codeController.text.toUpperCase(),
                          );
                          if (match != null) {
                            Navigator.pop(Get.context!);
                            Get.to(() => MatchWaitingScreen(
                                  match: match,
                                  isJoining: true,
                                ));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kpurple1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: MatchCreationController.instance.isJoiningMatch.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kwhite,
                        ),
                      )
                    : MyText(text: 'join'.tr, color: kwhite),
              )),
        ],
      ),
    );
  }
}

class _FeaturedCourtCard extends StatelessWidget {
  final CourtModel court;

  const _FeaturedCourtCard({required this.court});

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        MatchFormController.instance.selectCourt(court);
        Get.to(() => const SelectMatch());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: kgrey1.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Court Image
              court.imageUrl != null && court.imageUrl!.isNotEmpty
                  ? CommonImageView(
                      url: court.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 140,
                      width: double.infinity,
                      color: kpurple1.withOpacity(0.1),
                      child: const Icon(Icons.sports_tennis,
                          size: 48, color: kpurple1),
                    ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        kblack.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Court info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            text: court.name,
                            size: 16,
                            weight: FontWeight.bold,
                            color: kwhite,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 12, color: kwhite),
                              const SizedBox(width: 4),
                              Expanded(
                                child: MyText(
                                  text:
                                      court.address ?? 'location_not_specified'.tr,
                                  size: 12,
                                  color: kwhite.withOpacity(0.9),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kpurple1,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: MyText(
                        text: 'book'.tr,
                        size: 12,
                        color: kwhite,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Court type badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kwhite,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: MyText(
                    text: court.isIndoor ? 'indoor'.tr : 'outdoor'.tr,
                    size: 10,
                    color: kpurple1,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  final CourtModel court;

  const _CourtCard({required this.court});

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        MatchFormController.instance.selectCourt(court);
        Get.to(() => const SelectMatch());
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: kwhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kgrey2),
          boxShadow: [
            BoxShadow(
              color: kgrey1.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Court Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: court.imageUrl != null && court.imageUrl!.isNotEmpty
                  ? Image.network(
                      court.imageUrl!,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: court.name,
                    size: 14,
                    weight: FontWeight.bold,
                    color: kblack2,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        court.isIndoor ? Icons.home : Icons.wb_sunny,
                        size: 12,
                        color: kgrey1,
                      ),
                      const SizedBox(width: 4),
                      MyText(
                        text: court.isIndoor ? 'indoor'.tr : 'outdoor'.tr,
                        size: 11,
                        color: kgrey1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kpurple1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: MyText(
                      text: 'book_now'.tr,
                      size: 10,
                      color: kwhite,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 80,
      color: kgrey2,
      child: const Center(
        child: Icon(Icons.sports_tennis, size: 32, color: kgrey1),
      ),
    );
  }
}

class _ActiveMatchCard extends StatelessWidget {
  final MatchModel match;

  const _ActiveMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => PlayerMatchDetailScreen(match: match)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kpurple1.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kpurple1.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: kpurple1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_tennis, color: kpurple1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: '${match.player1Name} vs ${match.player2Name}',
                    size: 14,
                    weight: FontWeight.w600,
                    color: kblack2,
                  ),
                  const SizedBox(height: 4),
                  MyText(
                    text: '${match.formattedDate} • ${match.timeRangeDisplay}',
                    size: 12,
                    color: kgrey1,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(match.status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: MyText(
                text: match.status.displayName,
                size: 10,
                color: kwhite,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: kgrey1, size: 20),
          ],
        ),
      ),
    );
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
      default:
        return kpurple1;
    }
  }
}

class _AvailableMatchPreview extends StatelessWidget {
  final int count;

  const _AvailableMatchPreview({required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const AvailableMatchesScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kpurple1.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kpurple1.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kpurple1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_tennis, color: kpurple1, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: count == 1
                        ? '1 ${'match'.tr} ${'available_now'.tr}'
                        : '$count ${'matches'.tr} ${'available_now'.tr}',
                    size: 14,
                    weight: FontWeight.w600,
                    color: kblack2,
                  ),
                  const SizedBox(height: 4),
                  MyText(
                    text: 'tap_to_browse_match'.tr,
                    size: 12,
                    color: kgrey1,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kpurple1),
          ],
        ),
      ),
    );
  }
}

class _CheckInBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<PlayerMatchesController>();

    return Obx(() {
      final confirmedMatches = matchController.activeMatches
          .where((m) => m.status == MatchStatus.confirmed)
          .toList();

      if (confirmedMatches.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kpurple1, kpurple1.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: kpurple1.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kwhite.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner, color: kwhite, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: 'checkin_banner_title'.tr,
                    size: 16,
                    weight: FontWeight.bold,
                    color: kwhite,
                  ),
                  const SizedBox(height: 4),
                  MyText(
                    text: 'checkin_banner_subtitle'.tr,
                    size: 12,
                    color: kwhite.withOpacity(0.9),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => Get.to(() => const PlayerQRScannerScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kwhite,
                foregroundColor: kpurple1,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Check-in',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }
}
