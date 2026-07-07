import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/faq_controller.dart';

class FAQ extends StatelessWidget {
  const FAQ({super.key});

  @override
  Widget build(BuildContext context) {
    final faqController = Get.put(FaqController());

    return Scaffold(
      backgroundColor: kwhite,
      body: Obx(() {
        if (faqController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kpurple1),
          );
        }

        if (faqController.faqs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.help_outline, size: 48, color: kgrey1),
                const SizedBox(height: 12),
                MyText(
                  text: 'no_faqs_available'.tr,
                  size: 14,
                  color: kgrey1,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => faqController.loadFaqs(),
                  child: MyText(
                    text: 'retry'.tr,
                    size: 14,
                    color: kpurple1,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          physics: const BouncingScrollPhysics(),
          itemCount: faqController.faqs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final faq = faqController.faqs[index];
            return CustomAccordion(
              question: faq.question,
              answer: faq.answer,
            );
          },
        );
      }),
    );
  }
}

class CustomAccordion extends StatefulWidget {
  final String question;
  final String answer;

  const CustomAccordion({
    Key? key,
    required this.question,
    required this.answer,
  }) : super(key: key);

  @override
  State<CustomAccordion> createState() => _CustomAccordionState();
}

class _CustomAccordionState extends State<CustomAccordion> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: kwhite,
        ),
        child: Theme(
          data: ThemeData(
            dividerColor: kgrey2,
          ),
          child: ExpansionTile(
            title: MyText(
              text: widget.question,
              size: 16,
              weight: FontWeight.w700,
              color: kblack2,
            ),
            backgroundColor: kgrey2.withOpacity(0.5),
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Divider(color: kgrey2),
                    ),
                    ListTile(
                      title: MyText(
                        text: widget.answer,
                        size: 12,
                        weight: FontWeight.w500,
                        color: kblack2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onExpansionChanged: (bool expanded) {},
          ),
        ),
      ),
    );
  }
}
