import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/View/Screens/Users/Search/viewCardDetail.dart';
import 'package:orland_sports/controllers/explore_controller.dart';
import 'package:orland_sports/controllers/maps_controller.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/models/court_model.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    final ExploreController exploreController = Get.put(ExploreController());
    final MapsController mapsController = Get.put(MapsController());

    return Scaffold(
      body: SizedBox(
        height: Get.height,
        width: Get.width,
        child: Stack(
          children: [
            // Google Map
            Obx(() => GoogleMap(
                  initialCameraPosition: mapsController.defaultCameraPosition,
                  onMapCreated: exploreController.onMapCreated,
                  markers: exploreController.markers.toSet(),
                  onCameraMove: exploreController.onCameraMove,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  padding: mapsController.mapPadding,
                )),

            // Loading overlay
            Obx(() => exploreController.isLoading.value
                ? Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: kpurple1,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),

            // Search bar at the top
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: _buildSearchBar(exploreController),
            ),

            // Courts list at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCourtsList(exploreController),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the search bar widget
  Widget _buildSearchBar(ExploreController controller) {
    return Container(
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: MyTextField(
        hint: search,
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        suffixIcon: GestureDetector(
          onTap: () => _showFilterBottomSheet(controller),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Image.asset(
              Assets.imagesFilter2,
              width: 15,
            ),
          ),
        ),
      ),
    );
  }

  /// Build the horizontal courts list
  Widget _buildCourtsList(ExploreController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          if (controller.filteredCourts.isEmpty &&
              !controller.isLoading.value) {
            return _buildEmptyState();
          }

          return SizedBox(
            height: 130,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: controller.filteredCourts.length,
              itemBuilder: (context, index) {
                final court = controller.filteredCourts[index];
                return Obx(() => Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      margin: const EdgeInsets.only(right: 8),
                      child: CourtSearchCard(
                        court: court,
                        isSelected:
                            controller.selectedCourt.value?.id == court.id,
                        distance: controller.getDistanceString(court),
                        onTap: () => _onCourtCardTap(controller, court),
                      ),
                    ));
              },
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: MyText(
          text: 'no_courts_found_area'.tr,
          size: 14,
          color: kgrey1,
        ),
      ),
    );
  }

  /// Show filter bottom sheet
  void _showFilterBottomSheet(ExploreController controller) {
    Get.bottomSheet(
      AddFiltersWidget(
        minRadius: controller.minRadius.value,
        maxRadius: controller.maxRadius.value,
        onApply: (min, max) {
          controller.applyRadiusFilter(min, max);
          Navigator.pop(Get.context!);
        },
      ),
      isScrollControlled: true,
    );
  }

  /// Handle court card tap
  void _onCourtCardTap(ExploreController controller, CourtModel court) {
    controller.selectCourt(court);
    Get.bottomSheet(
      CourtDetailBottomSheet(court: court),
      isScrollControlled: true,
      barrierColor: ktransparent,
      backgroundColor: ktransparent,
      elevation: 0,
    );
  }
}

/// Court search card widget
class CourtSearchCard extends StatelessWidget {
  final CourtModel court;
  final bool isSelected;
  final String distance;
  final VoidCallback onTap;

  const CourtSearchCard({
    super.key,
    required this.court,
    required this.isSelected,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: kwhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isSelected
              ? const BorderSide(color: kpurple1, width: 2)
              : BorderSide.none,
        ),
        child: Row(
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: CommonImageView(
                url: court.imageUrl ?? '',
                width: 100,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title and Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: MyText(
                            text: court.name,
                            size: 16,
                            weight: FontWeight.bold,
                            color: kpurple1,
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Image.asset(
                              Assets.imagesTicket,
                              width: 24,
                              height: 24,
                            ),
                            MyText(
                              text: 'x1',
                              size: 12,
                              weight: FontWeight.bold,
                              color: kblack2,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Rating and Reviews
                    Row(
                      children: [
                        Image.asset(
                          Assets.imagesStar,
                          width: 16,
                          height: 16,
                        ),
                        MyText(
                          text: '5.0 (25 reviews)',
                          size: 12,
                          color: kblack2,
                          paddingLeft: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Distance
                    MyText(
                      text: distance,
                      size: 12,
                      color: kgrey1,
                    ),
                    // Sports tags
                    if (court.sports != null && court.sports!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          children: court.sports!.take(2).map((sport) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kgrey2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: MyText(
                                text: sport.name,
                                size: 10,
                                color: kgrey1,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter bottom sheet widget with reactive state
class AddFiltersWidget extends StatelessWidget {
  final double minRadius;
  final double maxRadius;
  final Function(double min, double max) onApply;

  AddFiltersWidget({
    super.key,
    required this.minRadius,
    required this.maxRadius,
    required this.onApply,
  });

  // Use Rx variables for reactive slider values
  final Rx<double> _minValue = 0.0.obs;
  final Rx<double> _maxValue = 30.0.obs;

  @override
  Widget build(BuildContext context) {
    // Initialize with passed values
    _minValue.value = minRadius;
    _maxValue.value = maxRadius;

    return Container(
      height: Get.height * 0.35,
      decoration: const BoxDecoration(
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kgrey4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                MyText(
                  text: locationradius,
                  color: kblack,
                  size: 20,
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 20),
                // Radius display
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MyText(
                          text: '${_minValue.value.toInt()} km',
                          size: 14,
                          color: kgrey1,
                        ),
                        MyText(
                          text: '${_maxValue.value.toInt()} km',
                          size: 14,
                          color: kgrey1,
                        ),
                      ],
                    )),
                const SizedBox(height: 10),
                // Range slider
                Obx(() => RangeSlider(
                      values: RangeValues(_minValue.value, _maxValue.value),
                      min: 0,
                      max: 50,
                      divisions: 50,
                      activeColor: kpurple1,
                      inactiveColor: kgrey4,
                      labels: RangeLabels(
                        '${_minValue.value.toInt()} km',
                        '${_maxValue.value.toInt()} km',
                      ),
                      onChanged: (values) {
                        _minValue.value = values.start;
                        _maxValue.value = values.end;
                      },
                    )),
                const SizedBox(height: 20),
                // Apply button
                ElevatedButton(
                  onPressed: () => onApply(_minValue.value, _maxValue.value),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kpurple1,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: MyText(
                    text: applyfilters,
                    color: kwhite,
                    size: 16,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Court detail bottom sheet
class CourtDetailBottomSheet extends StatelessWidget {
  final CourtModel court;

  const CourtDetailBottomSheet({
    super.key,
    required this.court,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      decoration: const BoxDecoration(
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kgrey4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: MyText(
                        text: court.name,
                        size: 18,
                        weight: FontWeight.bold,
                        color: kpurple1,
                      ),
                    ),
                    Image.asset(
                      Assets.imagesForwardicon,
                      width: 30,
                      height: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Rating
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
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        final url =
                            'https://www.google.com/maps/search/?api=1&query=${court.latitude},${court.longitude}';
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.directions,
                              color: kpurple1, size: 18),
                          const SizedBox(width: 4),
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
                const SizedBox(height: 15),
                // Address
                if (court.address != null)
                  MyText(
                    text: court.address!,
                    size: 14,
                    weight: FontWeight.w400,
                    color: kgrey1,
                  ),
                // Distance
                Obx(() {
                  final controller = Get.find<ExploreController>();
                  return MyText(
                    text: controller.getDistanceString(court),
                    size: 14,
                    weight: FontWeight.w400,
                    color: kgrey1,
                  );
                }),
                const SizedBox(height: 15),
                // Description
                MyText(
                  text: description,
                  size: 14,
                  weight: FontWeight.w700,
                  color: kblack,
                ),
                MyText(
                  text: court.description ?? 'No description available',
                  size: 14,
                  weight: FontWeight.w400,
                  color: kpurple1,
                  maxLines: 3,
                  textOverflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 15),
                // Gallery
                MyText(
                  text: gallery,
                  size: 14,
                  weight: FontWeight.w700,
                  color: kblack,
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.35,
                        margin: const EdgeInsets.only(right: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CommonImageView(
                            url: court.imageUrl ?? '',
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // View Details Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(Get.context!);
                    Get.to(() => ViewSearchCardDetail(court: court));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kpurple1,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: MyText(
                    text: viewDetails,
                    color: kwhite,
                    size: 16,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
