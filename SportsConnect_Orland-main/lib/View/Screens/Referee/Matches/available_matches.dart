import 'package:flutter/material.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/ManageMatch.dart';
import 'package:orland_sports/View/Widgets/dialogboxes_referre.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';

class AvailableMatches extends StatelessWidget {
  const AvailableMatches({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                MyText(
                  text: today,
                  size: 15,
                  weight: FontWeight.w600,
                  color: kblack2,
                  textAlign: TextAlign.center,
                  paddingBottom: 20,
                ),
                ListView.builder(
                    // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          manageMatchcard(
                            bgColor: kgrey2,
                            textColor: kgrey1,
                            statusColor: kgrey1,
                            dateortime1: 'Today',
                            Statustext: '02:00 pm',
                            weight: FontWeight.w400,
                            overallTap: () {
                              ReferreDialog.AcceptMatchDialog(
                                  'Yin ${vs} Dyroth');
                            },
                          ),
                          SizedBox(
                            height: 12,
                          ),
                        ],
                      );
                    }),
                MyText(
                  text: tomorrow,
                  size: 15,
                  weight: FontWeight.w600,
                  color: kblack2,
                  textAlign: TextAlign.center,
                  paddingBottom: 20,
                ),
                ListView.builder(
                    // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          manageMatchcard(
                            bgColor: kgrey2,
                            textColor: kgrey1,
                            statusColor: kgrey1,
                            Statustext: '02:00 pm',
                            weight: FontWeight.w400,
                            overallTap: () {
                              ReferreDialog.AcceptMatchDialog('Yin Vs Dyroth');
                            },
                          ),
                          SizedBox(
                            height: 12,
                          ),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
//
class ScheduledMatches extends StatelessWidget {
  const ScheduledMatches({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                MyText(
                  text: today,
                  size: 15,
                  weight: FontWeight.w600,
                  color: kblack2,
                  textAlign: TextAlign.center,
                  paddingBottom: 20,
                ),
                ListView.builder(
                    // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          manageMatchcard(
                            bgColor: kgrey2,
                            textColor: kgrey1,
                            statusColor: kpurple1,
                            dateortime1: '02:00 Pm',
                            Statustext: 'Yin Won',
                            weight: FontWeight.w600,
                            overallTap: () {
                              ReferreDialog.AcceptMatchDialog(
                                  'Yin ${vs} Dyroth');
                            },
                          ),
                          SizedBox(
                            height: 12,
                          ),
                        ],
                      );
                    }),
                MyText(
                  text: tomorrow,
                  size: 15,
                  weight: FontWeight.w600,
                  color: kblack2,
                  textAlign: TextAlign.center,
                  paddingBottom: 20,
                ),
                ListView.builder(
                    // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          manageMatchcard(
                            bgColor: kgrey2,
                            textColor: kgrey1,
                            statusColor: kpurple1,
                            dateortime1: '02:00 Pm',
                            Statustext: 'Yin Won',
                            weight: FontWeight.w600,
                            overallTap: () {
                              ReferreDialog.AcceptMatchDialog('Yin Vs Dyroth');
                            },
                          ),
                          SizedBox(
                            height: 12,
                          ),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
