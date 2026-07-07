import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/sport_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen to display detailed information about a court
class CourtDetailScreen extends StatelessWidget {
  final CourtModel court;

  const CourtDetailScreen({
    super.key,
    required this.court,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: kpurple1,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kblack.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: kwhite, size: 18),
              ),
              onPressed: () => Navigator.pop(Get.context!),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: court.imageUrl != null && court.imageUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CommonImageView(
                          url: court.imageUrl,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                kblack.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: kpurple1,
                      child: Icon(
                        Icons.sports_tennis,
                        size: 80,
                        color: kwhite.withOpacity(0.3),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Court Name & Status
                  Row(
                    children: [
                      Expanded(
                        child: MyText(
                          text: court.name,
                          size: 24,
                          weight: FontWeight.w700,
                          color: kblack2,
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (court.description != null &&
                      court.description!.isNotEmpty) ...[
                    MyText(
                      text: court.description!,
                      size: 14,
                      color: kgrey1,
                      lineHeight: 1.5,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Quick Info Cards
                  _buildQuickInfoSection(),
                  const SizedBox(height: 24),

                  // Sports Section
                  if (court.sports != null && court.sports!.isNotEmpty) ...[
                    _buildSectionTitle('available_sports'.tr),
                    const SizedBox(height: 12),
                    _buildSportsSection(),
                    const SizedBox(height: 24),
                  ],

                  // Location Section
                  _buildSectionTitle('location'.tr),
                  const SizedBox(height: 12),
                  _buildLocationCard(),
                  const SizedBox(height: 24),

                  // Contact Section
                  if (_hasContactInfo()) ...[
                    _buildSectionTitle('contact_information'.tr),
                    const SizedBox(height: 12),
                    _buildContactCard(),
                    const SizedBox(height: 24),
                  ],

                  // Amenities Section
                  if (court.amenities != null &&
                      court.amenities!.isNotEmpty) ...[
                    _buildSectionTitle('amenities'.tr),
                    const SizedBox(height: 12),
                    _buildAmenitiesSection(),
                    const SizedBox(height: 24),
                  ],

                  // Pricing Section
                  if (court.hourlyRate != null) ...[
                    _buildSectionTitle('pricing'.tr),
                    const SizedBox(height: 12),
                    _buildPricingCard(),
                    const SizedBox(height: 24),
                  ],

                  // Get Directions Button
                  MyButton(
                    onTap: _openMaps,
                    buttonText: 'get_directions'.tr,
                    fillColor: kpurple1,
                    fontColor: kwhite,
                    icon: Icons.directions,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color:
            court.isActive ? kteal.withOpacity(0.15) : kred.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: MyText(
        text: court.isActive ? 'active'.tr : 'inactive'.tr,
        size: 13,
        weight: FontWeight.w600,
        color: court.isActive ? kteal : kred,
      ),
    );
  }

  Widget _buildQuickInfoSection() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickInfoCard(
            icon: court.isIndoor ? Icons.home : Icons.wb_sunny,
            label: court.isIndoor ? 'indoor'.tr : 'outdoor'.tr,
            color: kblue,
          ),
        ),
        const SizedBox(width: 7),
        if (court.surfaceType != null && court.surfaceType!.isNotEmpty)
          Expanded(
            child: _buildQuickInfoCard(
              icon: Icons.grass,
              label: court.surfaceType!,
              color: kteal.withOpacity(0.2),
            ),
          ),
        const SizedBox(width: 7),
        if (court.openingTime != null && court.closingTime != null)
          Expanded(
            child: _buildQuickInfoCard(
              icon: Icons.access_time,
              label: '${court.openingTime} - ${court.closingTime}',
              color: kpurple3,
            ),
          ),
      ],
    );
  }

  Widget _buildQuickInfoCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: kpurple1),
          const SizedBox(height: 8),
          MyText(
            text: label,
            size: 11,
            weight: FontWeight.w500,
            color: kblack2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return MyText(
      text: title,
      size: 18,
      weight: FontWeight.w600,
      color: kblack2,
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kgrey2.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kgrey2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (court.address != null && court.address!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 20, color: kpurple1),
                const SizedBox(width: 8),
                Expanded(
                  child: MyText(
                    text: court.address!,
                    size: 14,
                    color: kblack2,
                    lineHeight: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Icon(Icons.my_location, size: 18, color: kgrey1),
              const SizedBox(width: 8),
              MyText(
                text: 'Lat: ${court.latitude.toStringAsFixed(6)}',
                size: 13,
                color: kgrey1,
              ),
              const SizedBox(width: 16),
              MyText(
                text: 'Lng: ${court.longitude.toStringAsFixed(6)}',
                size: 13,
                color: kgrey1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasContactInfo() {
    return (court.contactPhone != null && court.contactPhone!.isNotEmpty) ||
        (court.contactEmail != null && court.contactEmail!.isNotEmpty);
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kgrey2.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kgrey2),
      ),
      child: Column(
        children: [
          if (court.contactPhone != null && court.contactPhone!.isNotEmpty)
            _buildContactRow(
              icon: Icons.phone,
              value: court.contactPhone!,
              onTap: () => _makePhoneCall(court.contactPhone!),
            ),
          if (court.contactPhone != null &&
              court.contactPhone!.isNotEmpty &&
              court.contactEmail != null &&
              court.contactEmail!.isNotEmpty)
            const SizedBox(height: 12),
          if (court.contactEmail != null && court.contactEmail!.isNotEmpty)
            _buildContactRow(
              icon: Icons.email,
              value: court.contactEmail!,
              onTap: () => _sendEmail(court.contactEmail!),
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kpurple1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: kpurple1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
                  text: value,
                  size: 14,
                  color: kblack2,
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: kgrey1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: court.amenities!.map((amenity) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: kpurple1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: MyText(
            text: amenity,
            size: 13,
            weight: FontWeight.w500,
            color: kpurple1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSportsSection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: court.sports!.map((sport) {
        return _buildSportChip(sport);
      }).toList(),
    );
  }

  Widget _buildSportChip(SportModel sport) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: sport.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sport.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sport.icon,
            size: 18,
            color: sport.color,
          ),
          const SizedBox(width: 8),
          MyText(
            text: sport.name,
            size: 13,
            weight: FontWeight.w600,
            color: sport.color,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kpurple1, kpurple2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, size: 32, color: kwhite),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: '\$${court.hourlyRate!.toStringAsFixed(2)}',
                size: 24,
                weight: FontWeight.w700,
                color: kwhite,
              ),
              MyText(
                text: 'per_hour'.tr,
                size: 13,
                color: kwhite.withOpacity(0.8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${court.latitude},${court.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleaned = phoneNumber
        .replaceAll(RegExp(r'[^0-9+]'), '')
        .replaceAll(RegExp(r'\+(?=.+\+)'), '');
    if (cleaned.isEmpty) {
      _showContactLaunchError('invalid_phone_number'.tr);
      return;
    }

    final uri = Uri(scheme: 'tel', path: cleaned);
    await _launchContactUri(uri, 'could_not_open_phone'.tr);
  }

  Future<void> _sendEmail(String email) async {
    final cleaned = email.trim();
    if (cleaned.isEmpty || !cleaned.contains('@')) {
      _showContactLaunchError('invalid_email'.tr);
      return;
    }

    final uri = Uri(scheme: 'mailto', path: cleaned);
    await _launchContactUri(uri, 'could_not_open_email'.tr);
  }

  Future<void> _launchContactUri(Uri uri, String fallbackMessage) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showContactLaunchError(fallbackMessage);
      }
    } catch (_) {
      _showContactLaunchError(fallbackMessage);
    }
  }

  void _showContactLaunchError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: kred.withOpacity(0.9),
      colorText: kwhite,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
