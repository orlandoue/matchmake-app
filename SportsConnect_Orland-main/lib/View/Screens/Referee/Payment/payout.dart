import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/ExpandedRow.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/payout_controller.dart';
import 'package:orland_sports/services/payout_service.dart';

class ReferrePayout extends StatelessWidget {
  const ReferrePayout({super.key});

  @override
  Widget build(BuildContext context) {
    final payoutController = Get.put(PayoutController());

    return Scaffold(
      backgroundColor: kwhite,
      body: Obx(() {
        if (payoutController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kpurple1),
          );
        }

        final summary = payoutController.summary.value;

        return RefreshIndicator(
          onRefresh: () => payoutController.refresh(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PayoutHeader(
                weeklyMatches: summary.weeklyMatches,
                payoutController: payoutController,
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    MyText(
                      text: 'payment'.tr,
                      size: 18,
                      color: kblack2,
                      weight: FontWeight.w700,
                      paddingBottom: 20,
                    ),
                    ExpandedRow(
                      text1: 'pending_payouts'.tr,
                      text2: 'earning_in_month'.trParams({'month': payoutController.currentMonthName}),
                    ),
                    const SizedBox(height: 6),
                    ExpandedRow(
                      text1: payoutController
                          .formatCurrency(summary.pendingPayout),
                      text2: payoutController
                          .formatCurrency(summary.monthlyEarning),
                      color1: kblack2,
                      color2: kblack2,
                      weight1: FontWeight.w600,
                      weight2: FontWeight.w600,
                      size1: 16,
                      size2: 16,
                    ),
                    const SizedBox(height: 30),
                    ExpandedRow(
                      text1: 'Saldo Disponible',
                      text2: 'total_matches'.tr,
                    ),
                    const SizedBox(height: 6),
                    ExpandedRow(
                      text1:
                          payoutController.formatCurrency(summary.balance),
                      text2: '${summary.totalMatches}',
                      color1: kblack2,
                      color2: kblack2,
                      weight1: FontWeight.w600,
                      weight2: FontWeight.w600,
                      size1: 16,
                      size2: 16,
                    ),
                    const SizedBox(height: 30),
                    // Recent match history
                    if (payoutController.recentMatches.isNotEmpty) ...[
                      MyText(
                        text: 'recent_matches'.tr,
                        size: 18,
                        color: kblack2,
                        weight: FontWeight.w700,
                        paddingBottom: 12,
                      ),
                      ...payoutController.recentMatches
                          .map((m) => _PayoutMatchTile(match: m)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PayoutHeader extends StatelessWidget {
  final int weeklyMatches;
  final PayoutController payoutController;

  const _PayoutHeader({
    required this.weeklyMatches,
    required this.payoutController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        gradient: LinearGradient(
          colors: [kpurple1, kpurple2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            paddingTop: 40,
            paddingBottom: 15,
            text: 'payout'.tr,
            color: kwhite,
            size: 20,
            weight: FontWeight.w800,
            paddingLeft: 24,
            paddingRight: 24,
          ),
          Divider(color: kwhite.withOpacity(0.05)),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: kwhite.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports_score,
                    color: kwhite,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MyText(
                            text: 'matches_refereed'.tr,
                            color: kwhite,
                            size: 15,
                            weight: FontWeight.w500,
                          ),
                          MyText(
                            text: '( ${'this_week'.tr} )',
                            color: kwhite,
                            size: 12,
                            weight: FontWeight.w400,
                          ),
                        ],
                      ),
                      MyText(
                        paddingTop: 4,
                        text:
                            '$weeklyMatches ${weeklyMatches == 1 ? 'match_singular'.tr : 'matches_plural'.tr}',
                        color: kwhite,
                        size: 20,
                        weight: FontWeight.w800,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PayoutMatchTile extends StatelessWidget {
  final PayoutMatch match;

  const _PayoutMatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kgrey2),
        boxShadow: [
          BoxShadow(
            color: kgrey1.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kpurple1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_tennis, color: kpurple1, size: 22),
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
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                MyText(
                  text: '${match.courtName} • ${match.date}',
                  size: 12,
                  color: kgrey1,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          MyText(
            text: '\$${match.rate.toStringAsFixed(0)}',
            size: 16,
            weight: FontWeight.w700,
            color: kpurple1,
          ),
        ],
      ),
    );
  }
}
