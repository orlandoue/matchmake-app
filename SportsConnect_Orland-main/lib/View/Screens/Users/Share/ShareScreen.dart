import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/controllers/profile_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/utils/custom_toast.dart';

/// Share screen for inviting friends and sharing match info
class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<PlayerMatchesController>();
    final profileController = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'share'.tr,
        haveBackButton: false,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => matchController.loadPlayerMatches(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Share App Section
            _ShareAppCard(profileController: profileController),

            const SizedBox(height: 24),

            // Active Match Codes Section
            _ActiveMatchCodesSection(matchController: matchController),

            const SizedBox(height: 24),

            // Share Stats Section
            _ShareStatsCard(
              matchController: matchController,
              profileController: profileController,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card for sharing the app with friends
class _ShareAppCard extends StatelessWidget {
  final ProfileController profileController;

  const _ShareAppCard({required this.profileController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kpurple1, kpurple1.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kwhite.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people, color: kwhite, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: 'invite_friends'.tr,
                      size: 20,
                      weight: FontWeight.bold,
                      color: kwhite,
                    ),
                    const SizedBox(height: 4),
                    MyText(
                      text:
                          'Share Matchmake with your friends and play together!',
                      size: 13,
                      color: kwhite.withOpacity(0.9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final userName = profileController.userName;
                SharePlus.instance.share(
                  ShareParams(
                      text:
                          'Hey! Join me on Matchmake — the best app to find and play sports matches! '
                          'Download now and let\'s play together.\n\n'
                          '- $userName'),
                );
              },
              icon: const Icon(Icons.share, color: kpurple1),
              label: MyText(
                text: 'share_app'.tr,
                size: 16,
                weight: FontWeight.bold,
                color: kpurple1,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kwhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section showing active match codes that can be shared
class _ActiveMatchCodesSection extends StatelessWidget {
  final PlayerMatchesController matchController;

  const _ActiveMatchCodesSection({required this.matchController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'your_match_invite_codes'.tr,
          size: 18,
          weight: FontWeight.bold,
          color: kblack2,
          paddingBottom: 12,
        ),
        Obx(() {
          final matchesWithCodes = matchController.playerMatches
              .where((m) =>
                  m.inviteCode != null &&
                  m.inviteCode!.isNotEmpty &&
                  (m.status == MatchStatus.waitingForOpponent ||
                      m.status == MatchStatus.pending))
              .toList();

          if (matchesWithCodes.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kgrey2.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.code_off, size: 48, color: kgrey1),
                  const SizedBox(height: 12),
                  MyText(
                    text: 'no_active_invite_codes'.tr,
                    size: 14,
                    color: kgrey1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  MyText(
                    text:
                        'Create a friendly match to get a shareable invite code',
                    size: 12,
                    color: kgrey1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: matchesWithCodes
                .map((match) => _InviteCodeCard(match: match))
                .toList(),
          );
        }),
      ],
    );
  }
}

/// Individual invite code card
class _InviteCodeCard extends StatelessWidget {
  final dynamic match;

  const _InviteCodeCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kpurple1.withOpacity(0.3)),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kpurple1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.sports_tennis, color: kpurple1, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text:
                          '${match.matchType.displayName} · ${match.matchMode.displayName}',
                      size: 14,
                      weight: FontWeight.w600,
                      color: kblack2,
                    ),
                    MyText(
                      text:
                          '${match.court?.name ?? "Court"} · ${match.formattedDate}',
                      size: 12,
                      color: kgrey1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: kpurple1.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: MyText(
                text: match.inviteCode ?? '',
                size: 24,
                weight: FontWeight.bold,
                color: kpurple1,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: match.inviteCode ?? ''));
                    CustomToast.instance.showSuccessToast(
                      title: 'copied'.tr,
                      message: 'Invite code copied to clipboard',
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18, color: kpurple1),
                  label: MyText(
                    text: 'copy'.tr,
                    size: 13,
                    color: kpurple1,
                    weight: FontWeight.w600,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kpurple1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                          text: 'Join my match on Matchmake!\n\n'
                              'Invite Code: ${match.inviteCode}\n'
                              'Court: ${match.court?.name ?? "TBD"}\n'
                              'Date: ${match.formattedDate}\n'
                              'Time: ${match.timeRangeDisplay}\n'
                              'Type: ${match.matchType.displayName}'),
                    );
                  },
                  icon: const Icon(Icons.share, size: 18, color: kwhite),
                  label: MyText(
                    text: 'share'.tr,
                    size: 13,
                    color: kwhite,
                    weight: FontWeight.w600,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kpurple1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card showing sharable user stats
class _ShareStatsCard extends StatelessWidget {
  final PlayerMatchesController matchController;
  final ProfileController profileController;

  const _ShareStatsCard({
    required this.matchController,
    required this.profileController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'share_your_stats'.tr,
          size: 18,
          weight: FontWeight.bold,
          color: kblack2,
          paddingBottom: 12,
        ),
        Obx(() {
          final currentUserId = matchController.currentUserId;
          final completed = matchController.playerMatches
              .where((m) => m.status == MatchStatus.completed)
              .toList();
          final wins =
              completed.where((m) => m.winnerId == currentUserId).length;
          final total = completed.length;
          final rank = profileController.userRank;
          final winRate = total > 0 ? ((wins / total) * 100).toInt() : 0;

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kwhite,
              borderRadius: BorderRadius.circular(16),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'rank'.tr, value: rank),
                    _StatItem(label: 'wins'.tr, value: '$wins'),
                    _StatItem(label: 'matches'.tr, value: '$total'),
                    _StatItem(label: 'win_rate'.tr, value: '$winRate%'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final userName = profileController.userName;
                      SharePlus.instance.share(
                        ShareParams(
                            text: 'Check out my Matchmake stats!\n\n'
                                'Player: $userName\n'
                                'Rank: $rank\n'
                                'Matches Played: $total\n'
                                'Wins: $wins\n'
                                'Win Rate: $winRate%\n\n'
                                'Download Matchmake and challenge me!'),
                      );
                    },
                    icon: const Icon(Icons.share, color: kwhite),
                    label: MyText(
                      text: 'share_my_stats'.tr,
                      size: 14,
                      weight: FontWeight.bold,
                      color: kwhite,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kpurple1,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyText(
          text: value,
          size: 20,
          weight: FontWeight.bold,
          color: kpurple1,
        ),
        const SizedBox(height: 4),
        MyText(
          text: label,
          size: 12,
          color: kgrey1,
        ),
      ],
    );
  }
}
