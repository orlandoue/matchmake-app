import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/select_match.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/explore_controller.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/models/court_model.dart';

class ViewSearchCardDetail extends StatelessWidget {
  final CourtModel? court;
  const ViewSearchCardDetail({super.key, this.court});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
          haveBackButton: true, title: viewDetails, centerTitle: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
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
                          text: court?.isIndoor == true ? 'indoor'.tr : 'outdoor'.tr,
                          size: 14,
                          color: kblack2,
                          paddingLeft: 5,
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () async {
                            if (court != null) {
                              final url =
                                  'https://www.google.com/maps/search/?api=1&query=${court!.latitude},${court!.longitude}';
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.directions, color: kpurple1, size: 18),
                              SizedBox(width: 4),
                              MyText(
                                text: direction,
                                size: 14,
                                weight: FontWeight.w600,
                                color: kpurple1,
                              ),
                            ],
                          ),
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
                if (Get.isRegistered<ExploreController>())
                  Obx(() {
                    final controller = Get.find<ExploreController>();
                    return MyText(
                      text: court != null
                          ? controller.getDistanceString(court!)
                          : '',
                      size: 14,
                      weight: FontWeight.w400,
                      color: kgrey1,
                    );
                  }),
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
                  child: court?.imageUrl != null
                      ? ListView(
                          padding: EdgeInsets.only(top: 10),
                          scrollDirection: Axis.horizontal,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.35,
                              margin: const EdgeInsets.only(right: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CommonImageView(
                                  url: court!.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: MyText(
                            text: 'no_images_available'.tr,
                            size: 12,
                            color: kgrey1,
                          ),
                        ),
                ),
                SizedBox(
                  height: 20,
                ),
                // Sports tags
                if (court?.sports != null && court!.sports!.isNotEmpty) ...[
                  MyText(
                    text: 'Sports',
                    size: 14,
                    weight: FontWeight.w700,
                    color: kblack,
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: court!.sports!.map((sport) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kpurple1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MyText(
                          text: sport.name,
                          size: 12,
                          color: kpurple1,
                          weight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 15),
                ],
                // Court info
                if (court?.openingTime != null ||
                    court?.closingTime != null) ...[
                  MyText(
                    text: 'Hours',
                    size: 14,
                    weight: FontWeight.w700,
                    color: kblack,
                  ),
                  SizedBox(height: 4),
                  MyText(
                    text:
                        '${court?.openingTime ?? ''} - ${court?.closingTime ?? ''}',
                    size: 14,
                    color: kgrey1,
                  ),
                  SizedBox(height: 15),
                ],
                if (court?.surfaceType != null)
                  MyText(
                    text: 'Surface: ${court!.surfaceType}',
                    size: 14,
                    color: kgrey1,
                    paddingBottom: 8,
                  ),
                if (court?.hourlyRate != null)
                  MyText(
                    text: 'Rate: \$${court!.hourlyRate!.toStringAsFixed(2)}/hr',
                    size: 14,
                    color: kpurple1,
                    weight: FontWeight.w600,
                  ),
              ],
            ),
          ),
          MyButton(
            onTap: () {
              if (court != null) {
                final matchController = Get.find<MatchController>();
                matchController.selectCourt(court!);
                Get.to(() => SelectMatch(preSelectedCourt: court));
              }
            },
            buttonText: 'book_court'.tr,
            mBottom: 25,
            mhoriz: 20,
          )
        ],
      ),
    );
  }
}
