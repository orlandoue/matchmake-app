import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Matches/referee_match_detail_screen.dart';
import 'package:orland_sports/View/Screens/Referee/Matches/referee_matches_screen.dart';
import 'package:orland_sports/View/Widgets/ExpandedRow.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/referee_match_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';

class ReferreHome extends StatefulWidget {
  const ReferreHome({super.key});

  @override
  State<ReferreHome> createState() => _ReferreHomeState();
}

class _ReferreHomeState extends State<ReferreHome> {
  late final RefereeMatchController matchController;

  @override
  void initState() {
    super.initState();
    matchController = Get.find<RefereeMatchController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await matchController.loadRefereeAvailableMatches();
    await matchController.loadRefereeScheduledMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with next match info
          _buildHeader(matchController),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: kpurple1,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // --- MARKETPLACE SECTION ---
                  _buildMarketplaceSection(),

                  const SizedBox(height: 25),

                  // --- MY SCHEDULE SECTION ---
                  _buildMyScheduleSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(RefereeMatchController matchController) {
    return Container(
      color: kpurple1,
      padding: const EdgeInsets.only(top: 30, left: 10, right: 10, bottom: 20),
      child: Column(
        children: [
          HomeAppbarWidget(
            bgColor: kpurple1,
            textsColor: kwhite,
            isReferre: true,
          ),
          Divider(color: kwhite.withOpacity(0.2)),
        ],
      ),
    );
  }

  Widget _buildMarketplaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpandedRow(
          text1: 'Mercado de Partidos',
          text2: 'Partidos cercanos',
          size1: 18,
          size2: 12,
          color1: kblack2,
          color2: kgrey1,
          weight1: FontWeight.w800,
          weight2: FontWeight.w500,
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (matchController.isLoading.value &&
              matchController.refereeAvailableMatches.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: kpurple1),
              ),
            );
          }

          if (matchController.refereeAvailableMatches.isEmpty) {
            return _buildEmptyState(
              icon: Icons.search_off,
              title: 'No hay partidos disponibles',
              subtitle: 'Vuelve a revisar más tarde',
            );
          }

          return Column(
            children: matchController.refereeAvailableMatches
                .take(5)
                .map((match) => _MarketplaceMatchCard(match: match))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildMyScheduleSection() {
    return Column(
      children: [
        ExpandedRow(
          text1: 'Mis Próximos Partidos',
          text2: 'view_all_lower'.tr,
          size1: 18,
          size2: 14,
          color1: kblack2,
          color2: kpurple1,
          weight1: FontWeight.w800,
          weight2: FontWeight.w600,
          ontap2: () {
            Get.to(() => const RefereeMatchesScreen());
          },
        ),
        const SizedBox(height: 12),
        Obx(() {
          if (matchController.refereeScheduledMatches.isEmpty) {
            return _buildEmptyState(
              icon: Icons.event_note,
              title: 'schedule_empty'.tr,
              subtitle: 'claim_matches_hint'.tr,
            );
          }

          return Column(
            children: matchController.refereeScheduledMatches
                .take(3)
                .map((match) => _ScheduledMatchCard(match: match))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(
      {required IconData icon, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: kgrey2.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kgrey2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: kgrey1.withOpacity(0.5)),
          const SizedBox(height: 12),
          MyText(
            text: title,
            size: 14,
            weight: FontWeight.w600,
            color: kgrey1,
          ),
          const SizedBox(height: 4),
          MyText(
            text: subtitle,
            size: 12,
            color: kgrey1.withOpacity(0.8),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NextMatchCard extends StatelessWidget {
  final MatchModel match;

  const _NextMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<RefereeMatchController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kwhite.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kwhite.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPlayerInfo(
                  match.matchType == MatchType.twoVsTwo
                      ? match.team1DisplayName
                      : match.player1Name,
                  true),
              MyText(
                  text: 'vs'.tr,
                  size: 20,
                  weight: FontWeight.bold,
                  color: kwhite),
              _buildPlayerInfo(
                  match.matchType == MatchType.twoVsTwo
                      ? match.team2DisplayName
                      : match.player2Name,
                  false),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: kwhite, size: 14),
              const SizedBox(width: 4),
              MyText(
                text: match.court?.name ?? 'court'.tr,
                size: 14,
                color: kwhite.withOpacity(0.9),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (match.status == MatchStatus.confirmed)
            Obx(() {
              final allCheckedIn = match.areAllPlayersCheckedIn;
              final isLoading = matchController.isLoading.value;
              
              return ElevatedButton(
                onPressed: isLoading || !allCheckedIn
                    ? null
                    : () async {
                        await matchController.startMatch(match.id);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: allCheckedIn ? kwhite : kgrey1.withOpacity(0.3),
                  foregroundColor: allCheckedIn ? kpurple1 : kwhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kpurple1),
                      )
                    : Text(
                        allCheckedIn 
                          ? 'Iniciar Partido' 
                          : 'Esperando Check-in (${match.checkedInCount}/${match.totalSlots})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(String name, bool isPlayer1) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: kwhite.withOpacity(0.2),
          child: const Icon(Icons.person, color: kwhite, size: 25),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: MyText(
            text: name,
            size: 13,
            weight: FontWeight.w600,
            color: kwhite,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _MarketplaceMatchCard extends StatelessWidget {
  final MatchModel match;

  const _MarketplaceMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<RefereeMatchController>();

    return GestureDetector(
      onTap: () => Get.to(() => RefereeMatchDetailScreen(match: match)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kwhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kgrey2),
          boxShadow: [
            BoxShadow(
              color: kgrey1.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kpurple1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sports_tennis, color: kpurple1, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: match.matchType == MatchType.twoVsTwo
                            ? '${match.team1DisplayName} vs ${match.team2DisplayName}'
                            : '${match.player1Name} vs ${match.player2Name}',
                        size: 15,
                        weight: FontWeight.w700,
                        color: kblack2,
                        isEllipsized: true,
                      ),
                      const SizedBox(height: 4),
                      MyText(
                        text: '${match.court?.name ?? 'Geographic Flow'}',
                        size: 12,
                        color: kgrey1,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MyText(
                      text: match.timeRangeDisplay,
                      size: 14,
                      weight: FontWeight.w700,
                      color: kpurple1,
                    ),
                    MyText(
                      text: match.formattedShortDate,
                      size: 11,
                      color: kgrey1,
                    ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: kgrey1),
                      const SizedBox(width: 4),
                      Expanded(
                        child: MyText(
                          text: match.court?.address ?? 'Pending address',
                          size: 11,
                          color: kgrey1,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() {
                  final isThisLoading =
                      matchController.acceptingMatchId.value == match.id;
                  return ElevatedButton(
                    onPressed: isThisLoading
                        ? null
                        : () => matchController.claimMatch(match.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kpurple1,
                      foregroundColor: kwhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isThisLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: kwhite),
                          )
                        : Text('claim_match'.tr,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledMatchCard extends StatelessWidget {
  final MatchModel match;

  const _ScheduledMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => RefereeMatchDetailScreen(match: match)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kpurple1.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kpurple1.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: match.matchType == MatchType.twoVsTwo
                        ? '${match.team1DisplayName} vs ${match.team2DisplayName}'
                        : '${match.player1Name} vs ${match.player2Name}',
                    size: 14,
                    weight: FontWeight.w600,
                    color: kblack2,
                    isEllipsized: true,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: kgrey1),
                      const SizedBox(width: 4),
                      MyText(
                        text: '${match.formattedDate} • ${match.timeRangeDisplay}',
                        size: 11,
                        color: kgrey1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(match.status),
                borderRadius: BorderRadius.circular(6),
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
      case MatchStatus.confirmed:
        return Colors.blue;
      case MatchStatus.inProgress:
        return Colors.green;
      case MatchStatus.completed:
        return kpurple1;
      default:
        return kgrey1;
    }
  }
}
