import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_form_controller.dart';
import 'package:orland_sports/models/court_model.dart';

class SelectCourtScreen extends StatelessWidget {
  const SelectCourtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<MatchFormController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'select_court'.tr,
        haveBackButton: true,
        centerTitle: false,
        actions: [
          ticketcount(),
          const SizedBox(width: 13),
        ],
      ),
      body: Obx(() {
        if (matchController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kpurple1),
          );
        }

        if (matchController.availableCourts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_tennis, size: 64, color: kgrey1),
                const SizedBox(height: 16),
                MyText(
                  text: 'no_courts_available'.tr,
                  size: 16,
                  color: kgrey1,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => matchController.loadAvailableCourts(),
                  child: Text('refresh'.tr),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matchController.availableCourts.length,
          itemBuilder: (context, index) {
            final court = matchController.availableCourts[index];
            return _CourtCard(court: court);
          },
        );
      }),
    );
  }
}

class _CourtCard extends StatelessWidget {
  final CourtModel court;

  const _CourtCard({required this.court});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<MatchFormController>();

    return Obx(() {
      final isSelected = matchController.selectedCourt.value?.id == court.id;

      return GestureDetector(
        onTap: () {
          matchController.selectCourt(court);
          Navigator.pop(Get.context!, court);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isSelected ? kpurple1.withOpacity(0.1) : kwhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? kpurple1 : kgrey2,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: kgrey1.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Court Image
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: court.imageUrl != null && court.imageUrl!.isNotEmpty
                    ? Image.network(
                        court.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),

              // Court Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: MyText(
                            text: court.name,
                            size: 18,
                            weight: FontWeight.bold,
                            color: kblack2,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: kpurple1,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: MyText(
                              text: 'selected'.tr,
                              size: 12,
                              color: kwhite,
                              weight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (court.address != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: kgrey1),
                          const SizedBox(width: 4),
                          Expanded(
                            child: MyText(
                              text: court.address!,
                              size: 14,
                              color: kgrey1,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: court.isIndoor ? Icons.home : Icons.wb_sunny,
                          text: court.isIndoor ? 'indoor'.tr : 'outdoor'.tr,
                        ),
                        const SizedBox(width: 8),
                        if (court.surfaceType != null)
                          _buildInfoChip(
                            icon: Icons.grass,
                            text: court.surfaceType!,
                          ),
                      ],
                    ),
                    if (court.sports != null && court.sports!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: court.sports!
                            .take(3)
                            .map((sport) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: kpurple1.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: MyText(
                                    text: sport.name,
                                    size: 12,
                                    color: kpurple1,
                                    weight: FontWeight.w500,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 150,
      color: kgrey2,
      child: Center(
        child: Icon(Icons.sports_tennis, size: 48, color: kgrey1),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kgrey2.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kgrey1),
          const SizedBox(width: 4),
          MyText(
            text: text,
            size: 12,
            color: kgrey1,
          ),
        ],
      ),
    );
  }
}
