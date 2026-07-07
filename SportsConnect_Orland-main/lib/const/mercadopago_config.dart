import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de Mercado Pago (Checkout Pro).
///
/// Las credenciales viven en `.env` (gitignored). Por defecto opera en
/// sandbox: producción requiere `MP_USE_SANDBOX=false` explícito en el
/// entorno del build.
///
/// ⚠️ Deuda pendiente (Fase 2): mover la creación de preferencias y la
/// verificación de pagos a una Edge Function de Supabase para que el
/// access token nunca viaje en el cliente.
class MercadoPagoConfig {
  static String get publicKey => dotenv.env['MP_PUBLIC_KEY'] ?? '';
  static String get accessToken => dotenv.env['MP_ACCESS_TOKEN'] ?? '';

  static String get testPublicKey => dotenv.env['MP_TEST_PUBLIC_KEY'] ?? '';
  static String get testAccessToken => dotenv.env['MP_TEST_ACCESS_TOKEN'] ?? '';

  /// Sandbox por defecto: solo `MP_USE_SANDBOX=false` habilita producción.
  static bool get useSandbox =>
      dotenv.env['MP_USE_SANDBOX']?.toLowerCase() != 'false';

  static String get activeAccessToken =>
      useSandbox ? testAccessToken : accessToken;

  static String get activePublicKey =>
      useSandbox ? testPublicKey : publicKey;

  // ─── Mercado Pago API ─────────────────────────────────────────────────────
  static const String apiBaseUrl = 'https://api.mercadopago.com';

  // ─── Pricing (CLP) ───────────────────────────────────────────────────────
  static const double ticketPriceSinglesCLP = 500.0;
  static const double ticketPriceDoublesCLP = 500.0;
  static const String currency = 'CLP';

  /// Returns the correct unit price for a given ticket type.
  static double priceForType(String ticketType) =>
      ticketType == 'doubles' ? ticketPriceDoublesCLP : ticketPriceSinglesCLP;
}
