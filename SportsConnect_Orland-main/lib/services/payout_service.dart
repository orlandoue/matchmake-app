import 'package:orland_sports/const/supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for referee payout/earnings operations
class PayoutService {
  PayoutService._privateConstructor();

  static PayoutService? _instance;

  static PayoutService get instance {
    _instance ??= PayoutService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  /// Get referee payout summary from completed matches
  Future<PayoutSummary> getRefereePayout(String refereeId) async {
    try {
      // Get user balance from users table
      final userResponse = await _supabase
          .from('users')
          .select('balance')
          .eq('id', refereeId)
          .maybeSingle();
      
      final double currentBalance = (userResponse?['balance'] as num?)?.toDouble() ?? 0.0;

      // Get all completed matches for this referee
      final completedMatches = await _supabase
          .from(SupabaseTables.matchesTable)
          .select('id, scheduled_date')
          .eq('referee_id', refereeId)
          .eq('status', 'completed');

      // Get in-progress/confirmed matches (pending payout)
      final pendingMatches = await _supabase
          .from(SupabaseTables.matchesTable)
          .select('id, scheduled_date')
          .eq('referee_id', refereeId)
          .inFilter('status', ['confirmed', 'in_progress']);

      // Calculate this week's matches
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      int weeklyMatchCount = 0;
      double totalEarning = 0;
      double monthlyEarning = 0;
      double pendingPayout = 0;

      for (final match in (completedMatches as List)) {
        final dateStr = match['scheduled_date'] as String?;
        final rate = 5000.0; // Fixed earning per match

        totalEarning += rate;

        if (dateStr != null) {
          final matchDate = DateTime.tryParse(dateStr);
          if (matchDate != null) {
            if (matchDate.isAfter(startOfWeek) ||
                _isSameDay(matchDate, startOfWeek)) {
              weeklyMatchCount++;
            }
            if (matchDate.isAfter(startOfMonth) ||
                _isSameDay(matchDate, startOfMonth)) {
              monthlyEarning += rate;
            }
          }
        }
      }

      for (final match in (pendingMatches as List)) {
        final rate = 5000.0; // Fixed earning per match
        pendingPayout += rate;
      }

      return PayoutSummary(
        totalMatches: completedMatches.length,
        weeklyMatches: weeklyMatchCount,
        totalEarning: totalEarning,
        monthlyEarning: monthlyEarning,
        pendingPayout: pendingPayout,
        balance: currentBalance,
      );
    } catch (e, stack) {
      print('ERROR REAL DE PAYOUT: $e');
      print(stack);
      return PayoutSummary.empty();
    }
  }

  /// Get recent completed matches for payout history
  Future<List<PayoutMatch>> getRecentPayoutMatches(String refereeId,
      {int limit = 10}) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(
              'id, scheduled_date, scheduled_time, courts(name), player1:users!matches_player1_id_fkey(name), player2:users!matches_player2_id_fkey(name)')
          .eq('referee_id', refereeId)
          .eq('status', 'completed')
          .order('scheduled_date', ascending: false)
          .limit(limit);

      return (response as List).map((json) {
        final courtData = json['courts'] as Map<String, dynamic>?;
        final p1Data = json['player1'] as Map<String, dynamic>?;
        final p2Data = json['player2'] as Map<String, dynamic>?;
        return PayoutMatch(
          matchId: json['id'] as String,
          courtName: courtData?['name'] as String? ?? 'Unknown Court',
          rate: 5000.0, // Fixed rate for visual history
          date: json['scheduled_date'] as String? ?? '',
          time: json['scheduled_time'] as String? ?? '',
          player1Name: p1Data?['name'] as String? ?? 'Player 1',
          player2Name: p2Data?['name'] as String? ?? 'Player 2',
        );
      }).toList();
    } catch (e, stack) {
      print('ERROR REAL DE PAYOUT MATCHES: $e');
      print(stack);
      return [];
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Payout summary data model
class PayoutSummary {
  final int totalMatches;
  final int weeklyMatches;
  final double totalEarning;
  final double monthlyEarning;
  final double pendingPayout;
  final double balance;

  const PayoutSummary({
    required this.totalMatches,
    required this.weeklyMatches,
    required this.totalEarning,
    required this.monthlyEarning,
    required this.pendingPayout,
    required this.balance,
  });

  factory PayoutSummary.empty() => const PayoutSummary(
        totalMatches: 0,
        weeklyMatches: 0,
        totalEarning: 0,
        monthlyEarning: 0,
        pendingPayout: 0,
        balance: 0.0,
      );
}

/// Single payout match entry
class PayoutMatch {
  final String matchId;
  final String courtName;
  final double rate;
  final String date;
  final String time;
  final String player1Name;
  final String player2Name;

  const PayoutMatch({
    required this.matchId,
    required this.courtName,
    required this.rate,
    required this.date,
    required this.time,
    required this.player1Name,
    required this.player2Name,
  });
}
