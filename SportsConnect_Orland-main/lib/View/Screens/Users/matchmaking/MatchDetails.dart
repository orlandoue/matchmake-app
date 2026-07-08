import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/MatchDetailSearch.dart';
import 'package:orland_sports/View/Widgets/MatchDetailContainer.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';

class MatchDetails extends StatelessWidget {
  const MatchDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
          title: matchDetail,
          haveBackButton: true,
          centerTitle: false,
          actions: [
            IconButton(
                onPressed: () {},
                icon: Image.asset(
                  Assets.imagesShare,
                  width: 20,
                  height: 20,
                ))
          ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                Matchdetailcontainer(
                  twoPlayer: true,
                ),
                SizedBox(
                  height: 20,
                ),

                MyTextField(
                  hint: 'CRB123  |',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(Assets.imagesCopy,width: 12,height: 12,),
                  ),
                ),
                // Container(
                //   height: 114,
                //   decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(12),
                //       gradient: LinearGradient(colors: [kgrey3, kgrey4])),
                // ),
                // SizedBox(
                //   height: 20,
                // ),
                // Container(
                //   height: 44,
                //   decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(12),
                //       gradient: LinearGradient(colors: [kgrey3, kgrey4])),
                // ),
                // SizedBox(
                //   height: 15,
                // ),
       
              ],
            ),
          ),
                   MyButton(
                  onTap: () {
                    Get.to(()=>MatchDetailAfterSearch(
twoPlayer: true,
                    ));
                  },
                  buttonText: searchingForMatch,
                  fillColor: kwhite,
                  outlineColor: kpurple1,
                  fontColor: kpurple1,
                  mBottom: 40,
                  mhoriz: 20,
                ),
        ],
      ),
    );
  }
}
