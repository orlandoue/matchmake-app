import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';

class ReferreQRCode extends StatelessWidget {
  const ReferreQRCode({super.key});

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'my_qr_code'.tr,
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                CommonImageView(
                  imagePath: Assets.imagesQr,
                  height: 275,
                  
                )
              ],
            ),
          ),
        ],
      ),
    );

  }
}