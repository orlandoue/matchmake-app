import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for Mercado Pago payment operations.
///
/// La app NUNCA habla con api.mercadopago.com: toda la lógica de pagos vive
/// en las Edge Functions `create_preference` (crea la preferencia con precios
/// de la BD) y `mp_webhook` (verifica y acredita server-side). Aquí solo se
/// invoca la función y se consulta el estado de la transacción resultante.
class MercadoPagoService {
  MercadoPagoService._privateConstructor();

  static MercadoPagoService? _instance;

  static MercadoPagoService get instance {
    _instance ??= MercadoPagoService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  /// Crea una preferencia de Checkout Pro vía la Edge Function.
  ///
  /// El precio se calcula en el servidor (tabla `ticket_products`); el cliente
  /// solo envía tipo y cantidad. Devuelve `null` si la función falla.
  Future<MercadoPagoPreference?> createPreference({
    required int ticketQuantity,
    required String ticketType, // 'singles' | 'doubles'
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create_preference',
        body: {
          'ticket_type': ticketType,
          'ticket_quantity': ticketQuantity,
        },
      );

      final data = response.data;
      if (data is! Map || data['init_point'] == null) {
        return null;
      }

      return MercadoPagoPreference(
        id: data['preference_id'] as String,
        initPoint: data['init_point'] as String,
        externalReference: data['external_reference'] as String,
        totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0,
        currency: data['currency'] as String? ?? 'CLP',
      );
    } on FunctionException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Consulta el estado de la transacción asociada a una compra.
  ///
  /// El estado lo escribe la Edge Function `mp_webhook`; el cliente solo lee.
  Future<String?> getTransactionStatus(String externalReference) async {
    try {
      final row = await _supabase
          .from('ticket_transactions')
          .select('payment_status')
          .eq('external_reference', externalReference)
          .maybeSingle();
      return row?['payment_status'] as String?;
    } catch (_) {
      return null;
    }
  }
}

/// Represents a Mercado Pago checkout preference created server-side.
class MercadoPagoPreference {
  final String id;
  final String initPoint;
  final String externalReference;
  final double totalAmount;
  final String currency;

  MercadoPagoPreference({
    required this.id,
    required this.initPoint,
    required this.externalReference,
    required this.totalAmount,
    required this.currency,
  });
}
