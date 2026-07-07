import 'package:flutter/material.dart';

class DialogService {
  // Private constructor
  DialogService._privateConstructor();

  // Singleton instance variable
  static DialogService? _instance;

  //This code ensures that the singleton instance is created only when it's accessed for the first time.
  //Subsequent calls to DialogService.instance will return the same instance that was created before.

  // Getter to access the singleton instance
  static DialogService get instance {
    _instance ??= DialogService._privateConstructor();
    return _instance!;
  }

  void showProgressDialog({required BuildContext context}) {
    //showing progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        child: Center(
          child: CircularProgressIndicator(),
        ),
        // child: Center(
        //   child: ColorFiltered(
        //     colorFilter: const ColorFilter.mode(
        //       kSecondaryColor,
        //       BlendMode.srcIn,
        //     ),
        //     child: Lottie.asset(
        //       'assets/json/loading.json',
        //       height: 250,
        //       width: 250,
        //     ),
        //   ),

        //   // child: Lottie.asset(
        //   //   'assets/json/loading.json',
        //   //   height: 200,
        //   //   width: 200,
        //   // ),
        // ),
      ),
    );
  }

  // quitAppDialogue({required VoidCallback onTap}) {
  //   return CustomDialog(
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       children: [
  //         MyText(
  //           text: 'Are you sure you want to quit app?',
  //           size: 15,
  //           weight: FontWeight.w700,
  //           textAlign: TextAlign.center,
  //           paddingTop: 32,
  //           paddingBottom: 16,
  //         ),
  //         const SizedBox(
  //           height: 18,
  //         ),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: [
  //             Expanded(
  //               child: MyButton(
  //                 buttonText: 'No',
  //                 // bgColor: Colors.green,
  //                 // fontWeight: FontWeight.w500,
  //                 onTap: () {
  //                   Navigator.pop(Get.context!);
  //                 },
  //               ),
  //             ),
  //             const SizedBox(
  //               width: 10,
  //             ),
  //             Expanded(
  //               child: MyButton(
  //                 buttonText: 'Yes',
  //                 // fontWeight: FontWeight.w500,
  //                 onTap: onTap,
  //                 // bgColor: Colors.red,
  //               ),
  //             ),
  //           ],
  //         )
  //       ],
  //     ),
  //   );
  // }
}
