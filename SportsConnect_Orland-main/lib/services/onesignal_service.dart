import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';

class OneSignalService {
  // Singleton pattern
  static final OneSignalService instance = OneSignalService._internal();
  OneSignalService._internal();

  // App ID de OneSignal (desde .env)
  String get _appId => dotenv.env['ONESIGNAL_APP_ID'] ?? '';

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      // Remover configuración restrictiva para loggear en debug mode si es necesario
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Iniciar el SDK
      OneSignal.initialize(_appId);

      // Solicitar permisos al usuario de forma proactiva
      await OneSignal.Notifications.requestPermission(true);

    } catch (e) {
      print('Error inicializando OneSignal: $e');
    }
  }

  /// Obtener el Player ID / Subscription ID registrado en OneSignal
  String? getPlayerId() {
    return OneSignal.User.pushSubscription.id;
  }
}
