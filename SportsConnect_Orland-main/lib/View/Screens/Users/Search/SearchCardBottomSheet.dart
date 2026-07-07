import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Search/viewCardDetail.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/models/court_model.dart';

class SearchCardBottomSheet extends StatelessWidget {
  final CourtModel? court;
  const SearchCardBottomSheet({super.key, this.court});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        color: kwhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                Image.asset(
                  Assets.imagesDivider,
                  width: 40,
                  height: 4,
                ),
                SizedBox(
                  height: 20,
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: MyText(
                            text: court?.name ?? 'Court',
                            size: 16,
                            weight: FontWeight.bold,
                            color: kpurple1,
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Image.asset(
                          Assets.imagesForwardicon,
                          width: 30,
                          height: 30,
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    // Rating and Reviews
                    Row(
                      children: [
                        Image.asset(
                          Assets.imagesStar,
                          width: 18,
                          height: 18,
                        ),
                        MyText(
                          text: '5.0 (25 reviews)',
                          size: 14,
                          color: kblack2,
                          paddingLeft: 5,
                        ),
                        Spacer(),
                        MyText(
                          text: direction,
                          size: 14,
                          weight: FontWeight.w400,
                          color: kgrey1,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                if (court?.address != null)
                  MyText(
                    text: court!.address!,
                    size: 14,
                    weight: FontWeight.w400,
                    color: kgrey1,
                  ),
                SizedBox(
                  height: 15,
                ),
                MyText(
                  text: description,
                  size: 14,
                  weight: FontWeight.w700,
                  color: kblack,
                ),
                MyText(
                  text: court?.description ?? 'no_description_available'.tr,
                  size: 14,
                  weight: FontWeight.w400,
                  color: kpurple1,
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: 15,
                ),
                MyText(
                  text: gallery,
                  size: 14,
                  weight: FontWeight.w700,
                  color: kblack,
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: court?.imageUrl != null ? 1 : 0,
                    itemBuilder: (context, index) {
                      return Container(
                          width: MediaQuery.of(context).size.width * 0.35,
                          margin: const EdgeInsets.only(right: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CommonImageView(
                              url: court?.imageUrl ?? '',
                              fit: BoxFit.cover,
                            ),
                          ));
                    },
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                MyButton(
                  onTap: () {
                    Get.to(() => ViewSearchCardDetail(court: court));
                  },
                  buttonText: viewDetails,
                  mBottom: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
