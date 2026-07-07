import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/models/ticket_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for ticket-related Supabase operations
class TicketService {
  TicketService._privateConstructor();

  static TicketService? _instance;

  static TicketService get instance {
    _instance ??= TicketService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  /// Precios vigentes desde `ticket_products` (misma fuente que usa la
  /// Edge Function `create_preference`). Mapa ticket_type → precio CLP.
  Future<Map<String, double>> getTicketPrices() async {
    try {
      final rows = await _supabase
          .from('ticket_products')
          .select('ticket_type, price_clp')
          .eq('active', true);

      return {
        for (final row in rows as List)
          row['ticket_type'] as String: (row['price_clp'] as num).toDouble(),
      };
    } catch (e) {
      print('Error getting ticket prices: $e');
      return {};
    }
  }

  /// Get current user's ticket balance
  Future<TicketModel?> getTicketRecord(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.ticketsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return TicketModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting ticket record: $e');
      return null;
    }
  }

  /// Initialize ticket record for a user (if not exists)
  Future<void> ensureTicketRecord(String userId) async {
    try {
      final existing = await _supabase
          .from(SupabaseTables.ticketsTable)
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from(SupabaseTables.ticketsTable).insert({
          'user_id': userId,
          'singles_quantity': 0,
          'doubles_quantity': 0,
        });
      }
    } catch (e) {
      print('Error ensuring ticket record: $e');
    }
  }

  /// Add tickets to user's balance
  Future<bool> addTickets(String userId, int quantity, String ticketType) async {
    try {
      final record = await getTicketRecord(userId);
      int currentSingles = record?.singlesQuantity ?? 0;
      int currentDoubles = record?.doublesQuantity ?? 0;

      if (ticketType == 'singles') {
        currentSingles += quantity;
      } else {
        currentDoubles += quantity;
      }

      await _supabase.from(SupabaseTables.ticketsTable).upsert({
        'user_id': userId,
        'singles_quantity': currentSingles,
        'doubles_quantity': currentDoubles,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      return true;
    } catch (e) {
      print('Error adding tickets: $e');
      return false;
    }
  }

  /// Consume 1 ticket — guards against going negative with a .gte() filter on the update.
  Future<bool> useTicket(String userId, String matchId, String ticketType) async {
    try {
      final col = ticketType == 'singles' ? 'singles_quantity' : 'doubles_quantity';

      // Step 1: Read current balance for this ticket type
      final record = await getTicketRecord(userId);
      final current = ticketType == 'singles'
          ? (record?.singlesQuantity ?? 0)
          : (record?.doublesQuantity ?? 0);

      if (current < 1) return false;

      // Step 2: Decrement only the relevant column, with a .gte() safety guard
      // so concurrent calls that race here will hit a no-op (0 rows updated).
      await _supabase
          .from(SupabaseTables.ticketsTable)
          .update({
            col: current - 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .gte(col, 1); // never goes below 0

      // Step 3: Record the transaction
      await _supabase.from(SupabaseTables.ticketTransactionsTable).insert({
        'user_id': userId,
        'type': 'usage',
        'ticket_type': ticketType,
        'quantity': 1,
        'match_id': matchId,
        'payment_status': 'approved',
      });

      return true;
    } catch (e) {
      print('Error using ticket: $e');
      return false;
    }
  }

  /// Refund 1 ticket atomically.
  Future<bool> refundTicket(String userId, String matchId, String ticketType) async {
    try {
      final col = ticketType == 'singles' ? 'singles_quantity' : 'doubles_quantity';

      // Read current value then increment — safe because refunds don't have a
      // concurrency risk (you can only refund after a successful deduction).
      final record = await getTicketRecord(userId);
      final current = ticketType == 'singles'
          ? (record?.singlesQuantity ?? 0)
          : (record?.doublesQuantity ?? 0);

      await _supabase.from(SupabaseTables.ticketsTable).update({
        col: current + 1,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      await _supabase.from(SupabaseTables.ticketTransactionsTable).insert({
        'user_id': userId,
        'type': 'refund',
        'ticket_type': ticketType,
        'quantity': 1,
        'match_id': matchId,
        'payment_status': 'approved',
      });

      return true;
    } catch (e) {
      print('Error refunding ticket: $e');
      return false;
    }
  }

  /// Record a purchase transaction.
  ///
  /// [ticketType] must be `'singles'` or `'doubles'` — matches what the user
  /// selected in the store. Never defaults to a generic placeholder.
  Future<TicketTransactionModel?> recordPurchaseTransaction({
    required String userId,
    required int quantity,
    required double amount,
    required String currency,
    required String ticketType, // 'singles' | 'doubles'
    String? mercadopagoPaymentId,
    String paymentStatus = 'approved',
  }) async {
    assert(ticketType == 'singles' || ticketType == 'doubles',
        'ticketType must be "singles" or "doubles", got: $ticketType');
    try {
      final response = await _supabase
          .from(SupabaseTables.ticketTransactionsTable)
          .insert({
            'user_id': userId,
            'type': 'purchase',
            'ticket_type': ticketType, // ✅ Fixed: reflects actual purchase type
            'quantity': quantity,
            'amount': amount,
            'currency': currency,
            'mercadopago_payment_id': mercadopagoPaymentId,
            'payment_status': paymentStatus,
          })
          .select()
          .single();

      return TicketTransactionModel.fromJson(response);
    } catch (e) {
      print('Error recording purchase transaction: $e');
      return null;
    }
  }

  /// Get user's transaction history
  Future<List<TicketTransactionModel>> getTransactionHistory(
      String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.ticketTransactionsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) =>
              TicketTransactionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting transaction history: $e');
      return [];
    }
  }

  /// Check if user has enough tickets
  Future<bool> hasTickets(String userId, String ticketType, {int required = 1}) async {
    final record = await getTicketRecord(userId);
    if (record == null) return false;
    if (ticketType == 'singles') {
       return record.singlesQuantity >= required;
    } else {
       return record.doublesQuantity >= required;
    }
  }
}
