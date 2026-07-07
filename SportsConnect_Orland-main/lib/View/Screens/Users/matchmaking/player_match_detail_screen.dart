import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/utils/custom_toast.dart';

/// Detailed view of a player's match
class PlayerMatchDetailScreen extends StatelessWidget {
  final MatchModel match;

  const PlayerMatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<MatchController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'match_details'.tr,
        haveBackButton: true,
        centerTitle: false,
        actions: [
          if (match.inviteCode != null && match.inviteCode!.isNotEmpty)
            IconButton(
              onPressed: () => _shareMatch(),
              icon: const Icon(Icons.share, color: kblack2),
            ),
        ],
      ),
      body: Obx(() {
        // Get the latest match data from controller if available
        final currentMatch = matchController.playerMatches
                .firstWhereOrNull((m) => m.id == match.id) ??
            match;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Header
              _StatusHeader(match: currentMatch),

              const SizedBox(height: 24),

              // Players Section
              _PlayersSection(match: currentMatch),

              const SizedBox(height: 24),

              // Match Info Section
              _MatchInfoSection(match: currentMatch),

              const SizedBox(height: 24),

              // Court Section
              if (currentMatch.court != null)
                _CourtSection(match: currentMatch),

              const SizedBox(height: 24),

              // Invite Code Section (for waiting matches)
              if (currentMatch.status == MatchStatus.waitingForOpponent &&
                  currentMatch.inviteCode != null)
                _InviteCodeSection(match: currentMatch),

              const SizedBox(height: 24),

              // Action Buttons
              _ActionButtons(match: currentMatch),
            ],
          ),
        );
      }),
    );
  }

  void _shareMatch() {
    if (match.inviteCode != null) {
      SharePlus.instance.share(
        ShareParams(
            text: '${'join_match_text'.tr}\n\n'
                '${'invite_code_label'.tr}: ${match.inviteCode}\n'
                '${'court'.tr}: ${match.court?.name ?? 'tbd'.tr}\n'
                '${'date'.tr}: ${match.formattedDate}\n'
                '${'time'.tr}: ${match.timeRangeDisplay}'),
      );
    }
  }
}

class _StatusHeader extends StatelessWidget {
  final MatchModel match;

  const _StatusHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(match.status).withOpacity(0.1),
            _getStatusColor(match.status).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(match.status).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(match.status),
            size: 48,
            color: _getStatusColor(match.status),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(match.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: MyText(
              text: match.status.displayName,
              size: 14,
              color: kwhite,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          MyText(
            text: _getStatusDescription(match.status),
            size: 13,
            color: kgrey1,
            textAlign: TextAlign.center,
          ),
        ],
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
      case MatchStatus.completed:
        return kpurple1;
      case MatchStatus.cancelled:
        return kred;
      default:
        return kgrey1;
    }
  }

  IconData _getStatusIcon(MatchStatus status) {
    switch (status) {
      case MatchStatus.waitingForOpponent:
        return Icons.hourglass_empty;
      case MatchStatus.matched:
        return Icons.people;
      case MatchStatus.confirmed:
        return Icons.check_circle;
      case MatchStatus.inProgress:
        return Icons.play_circle_filled;
      case MatchStatus.completed:
        return Icons.emoji_events;
      case MatchStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.sports_tennis;
    }
  }

  String _getStatusDescription(MatchStatus status) {
    switch (status) {
      case MatchStatus.waitingForOpponent:
        return 'waiting_opponent_join'.tr;
      case MatchStatus.matched:
        return 'opponent_found_referee'.tr;
      case MatchStatus.confirmed:
        return 'match_confirmed_play'.tr;
      case MatchStatus.inProgress:
        return 'match_in_progress'.tr;
      case MatchStatus.completed:
        return 'match_completed_msg'.tr;
      case MatchStatus.cancelled:
        return 'match_cancelled_msg'.tr;
      default:
        return '';
    }
  }
}

class _PlayersSection extends StatelessWidget {
  final MatchModel match;

  const _PlayersSection({required this.match});

  @override
  Widget build(BuildContext context) {
    final is2v2 = match.matchType == MatchType.twoVsTwo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kgrey2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: is2v2 ? 'teams'.tr : 'players'.tr,
            size: 16,
            weight: FontWeight.bold,
            color: kblack2,
            paddingBottom: 16,
          ),
          if (is2v2) ...[
            // Team 1
            MyText(
              text: 'team_1'.tr,
              size: 13,
              weight: FontWeight.w600,
              color: kpurple1,
              paddingBottom: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: _PlayerCard(
                    name: match.player1Name,
                    isPlayer1: true,
                    imageUrl: match.player1?.profileImageUrl,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: match.player2Id != null
                      ? _PlayerCard(
                          name: match.player2Name,
                          isPlayer1: true,
                          imageUrl: match.player2?.profileImageUrl,
                        )
                      : _WaitingOpponentCard(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kpurple1,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: MyText(
                  text: 'VS',
                  size: 14,
                  color: kwhite,
                  weight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Team 2
            MyText(
              text: 'team_2'.tr,
              size: 13,
              weight: FontWeight.w600,
              color: Colors.blue,
              paddingBottom: 8,
            ),
            Row(
              children: [
                Expanded(
                  child: match.player3Id != null
                      ? _PlayerCard(
                          name: match.player3Name,
                          isPlayer1: false,
                          imageUrl: match.player3?.profileImageUrl,
                        )
                      : _WaitingOpponentCard(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: match.player4Id != null
                      ? _PlayerCard(
                          name: match.player4Name,
                          isPlayer1: false,
                          imageUrl: match.player4?.profileImageUrl,
                        )
                      : _WaitingOpponentCard(),
                ),
              ],
            ),
          ] else ...[
            // 1v1 layout
            Row(
              children: [
                Expanded(
                    child: _PlayerCard(
                  name: match.player1Name,
                  isPlayer1: true,
                  imageUrl: match.player1?.profileImageUrl,
                )),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kpurple1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: MyText(
                    text: 'VS',
                    size: 14,
                    color: kwhite,
                    weight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: match.player2Id != null
                      ? _PlayerCard(
                          name: match.player2Name,
                          isPlayer1: false,
                          imageUrl: match.player2?.profileImageUrl,
                        )
                      : _WaitingOpponentCard(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String name;
  final bool isPlayer1;
  final String? imageUrl;

  const _PlayerCard({
    required this.name,
    required this.isPlayer1,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin:
          EdgeInsets.only(left: isPlayer1 ? 0 : 8, right: isPlayer1 ? 8 : 0),
      decoration: BoxDecoration(
        color: kgrey2.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isPlayer1
                ? kpurple1.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                ? NetworkImage(imageUrl!)
                : null,
            child: imageUrl == null || imageUrl!.isEmpty
                ? Icon(
                    Icons.person,
                    color: isPlayer1 ? kpurple1 : Colors.blue,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          MyText(
            text: name,
            size: 13,
            weight: FontWeight.w600,
            color: kblack2,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _WaitingOpponentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.orange.withOpacity(0.2),
            child: const Icon(
              Icons.hourglass_empty,
              color: Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          MyText(
            text: 'waiting_dots'.tr,
            size: 13,
            weight: FontWeight.w600,
            color: Colors.orange,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MatchInfoSection extends StatelessWidget {
  final MatchModel match;

  const _MatchInfoSection({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kgrey2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'match_information'.tr,
            size: 16,
            weight: FontWeight.bold,
            color: kblack2,
            paddingBottom: 16,
          ),
          _InfoRow(
              icon: Icons.sports_tennis,
              label: 'type'.tr,
              value: match.matchType.displayName),
          _InfoRow(
              icon: Icons.calendar_today,
              label: 'date'.tr,
              value: match.formattedDate),
          _InfoRow(
              icon: Icons.access_time,
              label: 'time'.tr,
              value: match.timeRangeDisplay),
          _InfoRow(
            icon: Icons.shuffle,
            label: 'mode'.tr,
            value: match.matchMode.displayName,
          ),
          if (match.referee?.name != null)
            _InfoRow(
                icon: Icons.person_outline,
                label: 'referee'.tr,
                value: match.referee!.name!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kgrey1),
          const SizedBox(width: 12),
          MyText(text: '$label:', size: 14, color: kgrey1),
          const Spacer(),
          MyText(
              text: value, size: 14, color: kblack2, weight: FontWeight.w500),
        ],
      ),
    );
  }
}

class _CourtSection extends StatelessWidget {
  final MatchModel match;

  const _CourtSection({required this.match});

  @override
  Widget build(BuildContext context) {
    final court = match.court!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kgrey2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'court'.tr,
            size: 16,
            weight: FontWeight.bold,
            color: kblack2,
            paddingBottom: 16,
          ),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: kpurple1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.sports_tennis, color: kpurple1, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: court.name,
                      size: 15,
                      weight: FontWeight.w600,
                      color: kblack2,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          court.isIndoor ? Icons.home : Icons.wb_sunny,
                          size: 14,
                          color: kgrey1,
                        ),
                        const SizedBox(width: 4),
                        MyText(
                          text: court.isIndoor ? 'indoor'.tr : 'outdoor'.tr,
                          size: 12,
                          color: kgrey1,
                        ),
                      ],
                    ),
                    if (court.address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: kgrey1),
                          const SizedBox(width: 4),
                          Expanded(
                            child: MyText(
                              text: court.address!,
                              size: 12,
                              color: kgrey1,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteCodeSection extends StatelessWidget {
  final MatchModel match;

  const _InviteCodeSection({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kpurple1.withOpacity(0.1), kpurple1.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kpurple1.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.share, size: 32, color: kpurple1),
          const SizedBox(height: 12),
          MyText(
            text: 'share_with_friends'.tr,
            size: 16,
            weight: FontWeight.bold,
            color: kblack2,
          ),
          const SizedBox(height: 8),
          MyText(
            text: 'share_code_prompt'.tr,
            size: 13,
            color: kgrey1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: kwhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kpurple1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyText(
                  text: match.inviteCode!,
                  size: 24,
                  weight: FontWeight.bold,
                  color: kpurple1,
                  letterSpacing: 4,
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: match.inviteCode!));
                    CustomToast.instance.showSuccessToast(
                      title: 'copied'.tr,
                      message: 'invite_code_copied'.tr,
                    );
                  },
                  child: const Icon(Icons.copy, color: kpurple1, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final MatchModel match;

  const _ActionButtons({required this.match});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<MatchController>();

    if (match.status == MatchStatus.waitingForOpponent) {
      return MyButton(
        onTap: () => _showCancelConfirmation(match, matchController),
        buttonText: 'cancel_match'.tr,
        fillColor: kwhite,
        outlineColor: kred,
        fontColor: kred,
      );
    }

    if (match.status == MatchStatus.completed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kpurple1.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: kpurple1),
            const SizedBox(height: 12),
            MyText(
              text: 'match_completed_title'.tr,
              size: 18,
              weight: FontWeight.bold,
              color: kblack2,
            ),
            if (match.winnerId != null) ...[
              const SizedBox(height: 8),
              MyText(
                text:
                    '${'winner_label'.tr} ${match.winnerId == match.player1Id ? match.player1Name : match.player2Name}',
                size: 14,
                color: kpurple1,
                weight: FontWeight.w600,
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showCancelConfirmation(
      MatchModel match, MatchController matchController) {
    Get.dialog(
      AlertDialog(
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: MyText(
          text: 'cancel_match_question'.tr,
          size: 20,
          weight: FontWeight.bold,
          color: kblack2,
        ),
        content: MyText(
          text: 'cancel_match_confirm'.tr,
          size: 14,
          color: kgrey1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: MyText(text: 'no_keep_it'.tr, color: kgrey1),
          ),
          Obx(() => ElevatedButton(
                onPressed: matchController.isLoading.value
                    ? null
                    : () async {
                        await matchController.cancelMatch(match.id);
                        Navigator.pop(Get.context!);
                        Navigator.pop(Get.context!); // Go back to matches list
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kred,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: matchController.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kwhite),
                      )
                    : MyText(text: 'yes_cancel'.tr, color: kwhite),
              )),
        ],
      ),
    );
  }
}
