import 'package:get/get.dart';
import 'package:orland_sports/services/payout_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller for referee payout/earnings management
class PayoutController extends GetxController {
  static PayoutController get instance => Get.find<PayoutController>();

  final _payoutService = PayoutService.instance;

  // Loading state
  final RxBool isLoading = false.obs;

  // Payout data
  final Rx<PayoutSummary> summary = PayoutSummary.empty().obs;
  final RxList<PayoutMatch> recentMatches = <PayoutMatch>[].obs;

  /// Current user ID from Supabase auth
  String? get _refereeId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    loadPayoutData();
  }

  /// Load all payout data
  Future<void> loadPayoutData() async {
    final refereeId = _refereeId;
    if (refereeId == null) return;

    try {
      isLoading.value = true;
      final results = await Future.wait([
        _payoutService.getRefereePayout(refereeId),
        _payoutService.getRecentPayoutMatches(refereeId),
      ]);

      summary.value = results[0] as PayoutSummary;
      recentMatches.assignAll(results[1] as List<PayoutMatch>);
    } catch (e) {
      print('Error loading payout data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh payout data
  Future<void> refresh() async {
    await loadPayoutData();
  }

  /// Format currency
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Get current month name
  String get currentMonthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[DateTime.now().month - 1];
  }
}
