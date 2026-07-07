import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API key de Google Maps/Places para uso desde Dart (Places autocomplete).
/// La key usada por los SDK nativos de Maps se inyecta vía
/// `android/secrets.properties` (manifestPlaceholders) y
/// `ios/Flutter/Secrets.xcconfig` — no desde aquí.
class GoogleMapsConfig {
  static String get apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
}
