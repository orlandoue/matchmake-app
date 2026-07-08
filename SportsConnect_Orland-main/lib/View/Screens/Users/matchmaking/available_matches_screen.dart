import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/ReviewSummary.dart';
import 'package:orland_sports/View/Widgets/position_selector_modal.dart';
import 'package:intl/intl.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/select_match.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/controllers/match_creation_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/models/match_model.dart';

/// Screen to browse and join available matches
class AvailableMatchesScreen extends StatefulWidget {
  const AvailableMatchesScreen({super.key});

  @override
  State<AvailableMatchesScreen> createState() => _AvailableMatchesScreenState();
}

class _AvailableMatchesScreenState extends State<AvailableMatchesScreen> {

  static List<MatchModel> _getFilteredMatches(
      List<MatchModel> allMatches, String filter) {
    if (filter == '1v1') {
      return allMatches
          .where((match) => match.matchType == MatchType.oneVsOne)
          .toList();
    } else if (filter == '2v2') {
      return allMatches
          .where((match) => match.matchType == MatchType.twoVsTwo)
          .toList();
    }
    return allMatches;
  }

  final selectedFilter = 'all'.obs;
  late final PlayerMatchesController matchController;

  @override
  void initState() {
    super.initState();
    matchController = Get.find<PlayerMatchesController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      matchController.loadAvailableMatchesToJoin();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'find_a_match'.tr,
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
          // Pending Invitations Section (2v2)
          Obx(() {
             if (matchController.pendingInvitations.isEmpty) return const SizedBox.shrink();

             return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                      child: MyText(
                         text: 'Mis Invitaciones (2v2)',
                         size: 16,
                         weight: FontWeight.bold,
                         color: kpurple1,
                      ),
                   ),
                   SizedBox(
                      height: 160,
                      child: ListView.builder(
                         scrollDirection: Axis.horizontal,
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         itemCount: matchController.pendingInvitations.length,
                         itemBuilder: (context, index) {
                            final inv = matchController.pendingInvitations[index];
                            final dateFormat = DateFormat('MMM d');
                            final hostName = inv.player1Name;
                            return Container(
                               width: 260,
                               margin: const EdgeInsets.only(right: 12),
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(
                                  color: kpurple1.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: kpurple1.withOpacity(0.3)),
                               ),
                               child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Row(
                                        children: [
                                           Icon(Icons.mail_outline, color: kpurple1, size: 20),
                                           const SizedBox(width: 8),
                                           Expanded(child: MyText(text: 'Invita: $hostName', size: 14, weight: FontWeight.w600, color: kblack2, maxLines: 1)),
                                        ],
                                     ),
                                     const Spacer(),
                                     Row(
                                        children: [
                                           Icon(Icons.calendar_today, size: 12, color: kgrey1),
                                           const SizedBox(width: 4),
                                           MyText(text: dateFormat.format(inv.scheduledDate), size: 12, color: kgrey1),
                                           const SizedBox(width: 12),
                                           Icon(Icons.access_time, size: 12, color: kgrey1),
                                           const SizedBox(width: 4),
                                           MyText(text: inv.timeRangeDisplay, size: 12, color: kgrey1),
                                        ],
                                     ),
                                     const SizedBox(height: 12),
                                     Row(
                                        children: [
                                           Expanded(
                                              child: ElevatedButton(
                                                 onPressed: () => MatchCreationController.instance.rejectInvitation(inv),
                                                 style: ElevatedButton.styleFrom(
                                                    backgroundColor: kwhite,
                                                    padding: EdgeInsets.zero,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.red)),
                                                 ),
                                                 child: MyText(text: 'Rechazar', size: 12, color: Colors.red, weight: FontWeight.w600),
                                              ),
                                           ),
                                           const SizedBox(width: 8),
                                           Expanded(
                                              child: ElevatedButton(
                                                 onPressed: () => MatchCreationController.instance.acceptInvitation(inv),
                                                 style: ElevatedButton.styleFrom(
                                                    backgroundColor: kpurple1,
                                                    padding: EdgeInsets.zero,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                 ),
                                                 child: MyText(text: 'Aceptar', size: 12, color: kwhite, weight: FontWeight.w600),
                                              ),
                                           ),
                                        ],
                                     )
                                  ],
                               ),
                            );
                         },
                      ),
                   ),
                   const Divider(height: 32),
                ],
             );
          }),

          // Tab buttons for filtering
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() => Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: 'all_matches'.tr,
                        isSelected: selectedFilter.value == 'all',
                        onTap: () => selectedFilter.value = 'all',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'one_vs_one'.tr,
                        isSelected: selectedFilter.value == '1v1',
                        onTap: () => selectedFilter.value = '1v1',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'two_vs_two'.tr,
                        isSelected: selectedFilter.value == '2v2',
                        onTap: () => selectedFilter.value = '2v2',
                      ),
                    ),
                  ],
                )),
          ),

          // Available matches list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => matchController.loadAvailableMatchesToJoin(),
              child: Obx(() {
                if (matchController.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: kpurple1),
                  );
                }

                final filteredMatches = _getFilteredMatches(
                  matchController.availableMatchesToJoin,
                  selectedFilter.value,
                );

                if (filteredMatches.isEmpty) {
                  return _EmptyState(filterType: selectedFilter.value);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMatches.length,
                  itemBuilder: (context, index) {
                    final match = filteredMatches[index];
                    return _AvailableMatchCard(match: match);
                  },
                );
              }),
            ),
          ),

          // Create own match button
          Padding(
            padding: const EdgeInsets.all(16),
            child: MyButton(
              onTap: () => Get.to(() => const SelectMatch()),
              buttonText: 'create_your_own_match'.tr,
              fillColor: kwhite,
              outlineColor: kpurple1,
              fontColor: kpurple1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kpurple1 : kwhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? kpurple1 : kgrey2),
        ),
        child: Center(
          child: MyText(
            text: label,
            size: 12,
            weight: FontWeight.w600,
            color: isSelected ? kwhite : kgrey1,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filterType;

  const _EmptyState({this.filterType = 'all'});

  @override
  Widget build(BuildContext context) {
    String message;
    if (filterType == '1v1') {
      message = 'no_1v1_matches'.tr;
    } else if (filterType == '2v2') {
      message = 'no_2v2_matches'.tr;
    } else {
      message = 'no_open_matches'.tr;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kpurple1.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_tennis,
                size: 64,
                color: kpurple1,
              ),
            ),
            const SizedBox(height: 24),
            MyText(
              text: 'no_matches_available'.tr,
              size: 20,
              weight: FontWeight.bold,
              color: kblack2,
            ),
            const SizedBox(height: 12),
            MyText(
              text: message,
              size: 14,
              color: kgrey1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableMatchCard extends StatelessWidget {
  final MatchModel match;

  const _AvailableMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<PlayerMatchesController>();
    final dateFormat = DateFormat('EEE, MMM d');
    final formattedDate = dateFormat.format(match.scheduledDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Type Badge & Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kpurple1.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kpurple1,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: MyText(
                    text: match.matchType.displayName,
                    size: 12,
                    weight: FontWeight.bold,
                    color: kwhite,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 14, color: kgrey1),
                const SizedBox(width: 4),
                MyText(
                  text: formattedDate,
                  size: 12,
                  color: kgrey1,
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: kgrey1),
                const SizedBox(width: 4),
                MyText(
                  text: match.timeRangeDisplay,
                  size: 12,
                  color: kgrey1,
                ),
              ],
            ),
          ),

          // Match Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player info
                Row(
                  children: [
                    // Player 1 Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: kpurple1.withOpacity(0.1),
                      child: (match.player1?.profileImageUrl != null && match.matchMode != MatchMode.competitive)
                          ? ClipOval(
                              child: Image.network(
                                match.player1!.profileImageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person, color: kpurple1),
                              ),
                            )
                          : const Icon(Icons.person, color: kpurple1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              MyText(
                                text: match.matchMode == MatchMode.competitive
                                    ? 'Jugador Anónimo'
                                    : (match.matchType == MatchType.twoVsTwo
                                        ? match.team1DisplayName
                                        : (match.player1Name ?? 'Player')),
                                size: 16,
                                weight: FontWeight.bold,
                                color: kblack2,
                              ),
                              if (match.player1?.favoritePosition != null)
                                getPositionBadge(match.player1!.favoritePosition),
                            ],
                          ),
                          MyText(
                            text: match.matchType == MatchType.twoVsTwo
                                ? '${match.filledSlots}/${match.totalSlots} ${'players_joined'.tr}'
                                : 'looking_for_opponent'.tr,
                            size: 12,
                            color: kgrey1,
                          ),
                        ],
                      ),
                    ),
                    // VS indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kgrey2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: MyText(
                        text: 'VS',
                        size: 14,
                        weight: FontWeight.bold,
                        color: kblack2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Waiting indicator
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: kgrey2,
                      child: const Icon(Icons.person_add, color: kgrey1),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Court info
                if (match.court?.name != null)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: kgrey1),
                      const SizedBox(width: 4),
                      MyText(
                        text: match.court!.name,
                        size: 13,
                        color: kgrey1,
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Ticket cost & Join button
                Row(
                  children: [
                    // Ticket cost
                    Row(
                      children: [
                        Image.asset(
                          Assets.imagesTicket,
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 4),
                        MyText(
                          text: 'x1',
                          size: 14,
                          weight: FontWeight.bold,
                          color: kpurple1,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Join button - only show if player hasn't already joined
                    Obx(() {
                      final currentPlayerId = matchController.currentUserId;
                      final alreadyJoined = currentPlayerId != null &&
                          match.hasPlayer(currentPlayerId);

                      if (alreadyJoined || match.isFull) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: alreadyJoined
                                ? Colors.green.withOpacity(0.1)
                                : kgrey2,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: alreadyJoined ? Colors.green : kgrey1,
                            ),
                          ),
                          child: MyText(
                            text: alreadyJoined ? 'joined'.tr : 'full'.tr,
                            size: 14,
                            weight: FontWeight.bold,
                            color: alreadyJoined ? Colors.green : kgrey1,
                          ),
                        );
                      }

                      final isThisJoining =
                          MatchCreationController.instance.joiningMatchId.value == match.id;
                      return ElevatedButton(
                        onPressed: isThisJoining
                            ? null
                            : () {
                                PositionSelectorModal.show(
                                  onPositionSelected: (position) {
                                    Get.to(() => ReviewSummary(
                                      onConfirm: () async {
                                        // TODO: Pass position to joinAvailableMatch if supported
                                        final joinedMatch = await MatchCreationController.instance
                                            .joinAvailableMatch(match.id);
                                        if (joinedMatch != null) {
                                          Get.off(() => MatchWaitingScreen(
                                              match: joinedMatch));
                                          return true;
                                        }
                                        return false;
                                      },
                                    ));
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kpurple1,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isThisJoining
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kwhite,
                                ),
                              )
                            : MyText(
                                text: 'join_match'.tr,
                                size: 14,
                                weight: FontWeight.bold,
                                color: kwhite,
                              ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
