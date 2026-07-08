import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Events/Payments/AddMethod.dart';
import 'package:orland_sports/View/Widgets/Checkbox.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';

class PaymentMethod extends StatelessWidget {
  final String? title;
  final bool? hasButton;
  const PaymentMethod({super.key, this.title, this.hasButton=true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: selectPaymentMethod,
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
                if(hasButton==false)...{

                  GestureDetector(
                    onTap: (){
                      Get.to(()=>AddPaymentMethod(
                        buttonText: 'save'.tr,ontap: () {
                          Navigator.pop(Get.context!);
                        },
                      ));
                    },child: 
                PaymentmethodCard(
                  methodName:title?? 'Credit/Debit Card',
                  icon: Assets.imagesCreditcard,
                  isActive: true,
                  size: 24,
                ),
            ),
                SizedBox(
                  height: 20,
                ),
                },
                PaymentmethodCard(
                  methodName: 'Paypal',
                  icon: Assets.imagesPaypal,
                ),
                SizedBox(
                  height: 20,
                ),
                PaymentmethodCard(
                  methodName: 'Google Pay',
                  icon: Assets.imagesGoogle,
                  isActive: true,
                ),
                SizedBox(
                  height: 20,
                ),
                PaymentmethodCard(
                  methodName: 'Apple Pay',
                  icon: Assets.imagesApple,
                ),
                SizedBox(
                  height: 30,
                ),
                if(hasButton==true)
                MyButton(
                  onTap: () {
                    Get.to(() => AddPaymentMethod());
                  },
                  buttonText: addCard,
                  outlineColor: kpurple1,
                  fillColor: kwhite,
                  fontColor: kpurple1,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentmethodCard extends StatelessWidget {
  final String methodName;
  final String icon;
  final bool? isActive;
  final double? size;
  const PaymentmethodCard({
    super.key,
    required this.methodName,
    required this.icon,
    this.isActive,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: kgrey2),
      child: Row(
        children: [
          Image.asset(
            icon,
            width: size ?? 32,
            height: size ?? 35,
            fit: BoxFit.contain,
          ),
          MyText(
            text: methodName,
            size: 16,
            weight: FontWeight.w600,
            color: kblack,
            paddingLeft: 8,
          ),
          Spacer(),
          CustomCheckBox(
            isActive: isActive ?? false,
            onTap: () {},
            iscircle: true,
            size: 18,
          )
        ],
      ),
    );
  }
}
