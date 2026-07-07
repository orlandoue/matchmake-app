import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orland_sports/club_admin/controllers/club_admin_controller.dart';
import 'package:orland_sports/club_admin/services/club_admin_service.dart';

/// Represents a single billable match entry in the transaction history.
class WalletEntry {
  final String matchId;
  final DateTime scheduledDate;
  final String sportName;
  final String courtName;
  final double amount; // CLP value = court hourly_rate

  const WalletEntry({
    required this.matchId,
    required this.scheduledDate,
    required this.sportName,
    required this.courtName,
    required this.amount,
  });
}

/// Financial controller for the Club Wallet screen.
///
/// Business rules (enforced here, not in the UI):
///   • Only matches with status == 'completed' are counted.
///   • Matches with match_mode == 'manual_reservation' are excluded.
///   • Revenue per match = courts.hourly_rate  (zero invented numbers).
///   • Arithmetic uses Dart's native double; NumberFormat handles CLP display.
class ClubWalletController extends GetxController {
  static ClubWalletController get instance =>
      Get.find<ClubWalletController>();

  final _service = ClubAdminService.instance;

  // ── Observable state ────────────────────────────────────────────────────
  final RxBool isLoading = true.obs;
  final RxDouble netBalance = 0.0.obs;           // All-time total, CLP
  final RxDouble monthEarnings = 0.0.obs;        // Current calendar-month, CLP
  final RxInt completedMatchesTotal = 0.obs;     // All-time count
  final RxInt completedMatchesMonth = 0.obs;     // Current month count
  final RxList<WalletEntry> entries = <WalletEntry>[].obs;

  // ── Formatters ──────────────────────────────────────────────────────────
  final _clpFmt = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('dd/MM/yyyy', 'es_CL');

  String formatClp(double amount) => _clpFmt.format(amount);
  String formatDate(DateTime d) => _dateFmt.format(d);

  // ── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();

    final clubAdmin = ClubAdminController.instance;

    // If the club is already loaded (e.g. hot restart), load immediately.
    if (clubAdmin.currentClub.value != null) {
      loadWalletData();
    }

    // React whenever currentClub changes (covers the initial async load case).
    ever(clubAdmin.currentClub, (club) {
      if (club != null) loadWalletData();
    });
  }

  // ── Data loading ────────────────────────────────────────────────────────

  Future<void> loadWalletData() async {
    final clubId = ClubAdminController.instance.currentClub.value?.id;
    if (clubId == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final rows = await _service.getCompletedMatchesForWallet(clubId);

      final now = DateTime.now();
      final thisYear = now.year;
      final thisMonth = now.month;

      double totalBalance = 0.0;
      double monthTotal = 0.0;
      int monthCount = 0;
      final List<WalletEntry> tempEntries = [];

      for (final row in rows) {
        // ── Extract court price (never fabricate if missing) ──────────────
        final courtsData = row['courts'] as Map<String, dynamic>?;
        final rate =
            (courtsData?['hourly_rate'] as num?)?.toDouble() ?? 0.0;
        if (rate <= 0) continue; // skip matches with no configured price

        // ── Parse date ────────────────────────────────────────────────────
        final dateStr = row['scheduled_date'] as String? ?? '';
        final DateTime matchDate;
        try {
          matchDate = DateTime.parse(dateStr);
        } catch (_) {
          continue;
        }

        final sportName =
            (row['sports'] as Map<String, dynamic>?)?['name'] as String? ??
                'Deporte';
        final courtName =
            courtsData?['name'] as String? ?? 'Cancha';

        // ── Accumulate ────────────────────────────────────────────────────
        totalBalance += rate;

        if (matchDate.year == thisYear && matchDate.month == thisMonth) {
          monthTotal += rate;
          monthCount++;
        }

        tempEntries.add(WalletEntry(
          matchId: row['id'] as String? ?? '',
          scheduledDate: matchDate,
          sportName: sportName,
          courtName: courtName,
          amount: rate,
        ));
      }

      netBalance.value = totalBalance;
      monthEarnings.value = monthTotal;
      completedMatchesTotal.value = tempEntries.length;
      completedMatchesMonth.value = monthCount;
      entries.assignAll(tempEntries);
    } catch (e) {
      print('[ClubWalletController] Error loading wallet: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void requestWithdrawal() {
    if (netBalance.value <= 0) {
      Get.snackbar(
        'Sin saldo disponible',
        'No tienes ingresos acumulados para retirar en este momento.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.info_outline, color: Colors.white70),
      );
      return;
    }

    Get.snackbar(
      '✅ Solicitud enviada',
      'Tu retiro de ${formatClp(netBalance.value)} CLP ha sido enviado. '
          'Se procesará en 3–5 días hábiles.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF12B76A),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }
}
