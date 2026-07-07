import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:orland_sports/const/mercadopago_config.dart';

/// Service for Mercado Pago payment operations using Checkout Pro
class MercadoPagoService {
  MercadoPagoService._privateConstructor();

  static MercadoPagoService? _instance;

  static MercadoPagoService get instance {
    _instance ??= MercadoPagoService._privateConstructor();
    return _instance!;
  }

  /// Create a Mercado Pago Checkout Pro preference and return the checkout URL.
  ///
  /// [ticketType] must be `'singles'` or `'doubles'` — determines the unit price.
  Future<MercadoPagoPreference?> createPreference({
    required int ticketQuantity,
    required String ticketType, // 'singles' | 'doubles'
    required String userId,
    required String userEmail,
  }) async {
    try {
      final unitPrice = MercadoPagoConfig.priceForType(ticketType);
      final totalAmount = unitPrice * ticketQuantity;
      final typeLabel = ticketType == 'doubles' ? 'Dobles' : 'Singles';

      print('💳 [MercadoPagoService.createPreference] Creating preference');
      print('   ticketType: $ticketType');
      print('   ticketQuantity: $ticketQuantity');
      print('   userId: $userId');
      print('   userEmail: $userEmail');
      print('   unitPrice: $unitPrice ${MercadoPagoConfig.currency}');
      print('   totalAmount: $totalAmount ${MercadoPagoConfig.currency}');
      print('   useSandbox: ${MercadoPagoConfig.useSandbox}');

      final body = {
        'items': [
          {
            'title': 'Matchmake Ticket $typeLabel',
            'description':
                '$ticketQuantity ticket$typeLabel${ticketQuantity > 1 ? 's' : ''} para Matchmake',
            'quantity': ticketQuantity,
            'unit_price': unitPrice,
            'currency_id': MercadoPagoConfig.currency,
          }
        ],
        if (!MercadoPagoConfig.useSandbox) 'payer': {
          'email': userEmail,
        },
        'back_urls': {
          'success': 'sportsconnect://payment/success',
          'failure': 'sportsconnect://payment/failure',
          'pending': 'sportsconnect://payment/pending',
        },
        'auto_return': 'approved',
        'external_reference': 'user_$userId\_qty_$ticketQuantity',
        'metadata': {
          'user_id': userId,
          'ticket_quantity': ticketQuantity,
          'total_amount': totalAmount,
        },
      };

      print('💳 [MercadoPagoService.createPreference] Request body:');
      print('   ${body.toString()}');

      final endpoint = '${MercadoPagoConfig.apiBaseUrl}/checkout/preferences';
      print('💳 [MercadoPagoService.createPreference] Endpoint: $endpoint');
      print(
          '   Authorization Bearer: ${MercadoPagoConfig.activeAccessToken.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${MercadoPagoConfig.activeAccessToken}',
        },
        body: jsonEncode(body),
      );

      print(
          '💳 [MercadoPagoService.createPreference] Response status: ${response.statusCode}');
      print('   Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final preference = MercadoPagoPreference(
          id: data['id'] as String,
          initPoint: data['init_point'] as String,
          sandboxInitPoint: data['sandbox_init_point'] as String?,
        );
        print(
            '✅ [MercadoPagoService.createPreference] Preference created successfully');
        print('   ID: ${preference.id}');
        print('   Init Point: ${preference.initPoint}');
        print('   Sandbox Init Point: ${preference.sandboxInitPoint}');
        return preference;
      } else {
        print(
            '❌ [MercadoPagoService.createPreference] API error: ${response.statusCode}');
        print('   Error body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [MercadoPagoService.createPreference] Exception: $e');
      return null;
    }
  }

  /// Get payment status by payment ID
  Future<MercadoPagoPaymentStatus?> getPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('${MercadoPagoConfig.apiBaseUrl}/v1/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer ${MercadoPagoConfig.activeAccessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MercadoPagoPaymentStatus(
          id: data['id'].toString(),
          status: data['status'] as String,
          statusDetail: data['status_detail'] as String?,
          externalReference: data['external_reference'] as String?,
        );
      }
      return null;
    } catch (e) {
      print('Error getting payment status: $e');
      return null;
    }
  }

  /// Get the checkout URL based on sandbox mode
  String getCheckoutUrl(MercadoPagoPreference preference) {
    final isSandbox = MercadoPagoConfig.useSandbox;
    final hasSandboxUrl = preference.sandboxInitPoint != null;

    print('🔗 [MercadoPagoService.getCheckoutUrl] Determining checkout URL');
    print('   isSandbox: $isSandbox');
    print('   hasSandboxUrl: $hasSandboxUrl');

    if (isSandbox && hasSandboxUrl) {
      print('   → Using SANDBOX URL: ${preference.sandboxInitPoint}');
      return preference.sandboxInitPoint!;
    } else {
      print('   → Using PRODUCTION URL: ${preference.initPoint}');
      return preference.initPoint;
    }
  }
}

/// Represents a Mercado Pago checkout preference
class MercadoPagoPreference {
  final String id;
  final String initPoint;
  final String? sandboxInitPoint;

  MercadoPagoPreference({
    required this.id,
    required this.initPoint,
    this.sandboxInitPoint,
  });
}

/// Represents a Mercado Pago payment status
class MercadoPagoPaymentStatus {
  final String id;
  final String status;
  final String? statusDetail;
  final String? externalReference;

  MercadoPagoPaymentStatus({
    required this.id,
    required this.status,
    this.statusDetail,
    this.externalReference,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending' || status == 'in_process';
  bool get isRejected => status == 'rejected';
}
