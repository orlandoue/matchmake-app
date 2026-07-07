import 'package:flutter/material.dart';
import 'package:orland_sports/View/Widgets/ProgressIndicator.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';

class RankingCard extends StatelessWidget {
  final String? rankString;
  final double progress;
  final int lp;
  const RankingCard(
      {super.key, this.rankString, this.progress = 0.0, this.lp = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          gradient: LinearGradient(
              colors: [kpurple1, kpurple2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        children: [
          MyText(
            paddingTop: 18,
            text: rankString ?? rankingseason,
            size: 24,
            weight: FontWeight.bold,
            color: kwhite,
            paddingBottom: 24,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MyText(
                text:
                    '${(progress * 100).toInt()}% progress to next rank (${lp} LP)',
                color: kwhite,
                weight: FontWeight.w600,
                size: 12,
                paddingBottom: 8,
              ),
              myLinearProgressIndicator(
                fillColor: kpurple1,
                valueColor: kwhite,
                border: kwhite,
                progress: progress,
              ),
            ],
          ),
          SizedBox(
            height: 18,
          ),
          // Container(
          //   decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(10),
          //       color: kblack.withOpacity(0.25)),
          //   padding: EdgeInsets.all(8),
          //   child: MyText(
          //     text:
          //         participateToFinal,
          //     color: kwhite,
          //     size: 14,
          //     weight: FontWeight.w600,
          //     textAlign: TextAlign.center,
          //   ),
          // )
        ],
      ),
    );
  }
}
