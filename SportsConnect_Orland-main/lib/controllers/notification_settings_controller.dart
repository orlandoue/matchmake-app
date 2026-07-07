import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing notification preference toggles
class NotificationSettingsController extends GetxController {
  static NotificationSettingsController get instance =>
      Get.find<NotificationSettingsController>();

  // Notification toggles
  final RxBool generalNotifications = false.obs;
  final RxBool events = true.obs;
  final RxBool matches = true.obs;
  final RxBool offers = true.obs;
  final RxBool news = true.obs;
  final RxBool payment = true.obs;
  final RxBool vibrate = false.obs;
  final RxBool others = false.obs;

  static const String _prefix = 'notification_';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    generalNotifications.value = prefs.getBool('${_prefix}general') ?? false;
    events.value = prefs.getBool('${_prefix}events') ?? true;
    matches.value = prefs.getBool('${_prefix}matches') ?? true;
    offers.value = prefs.getBool('${_prefix}offers') ?? true;
    news.value = prefs.getBool('${_prefix}news') ?? true;
    payment.value = prefs.getBool('${_prefix}payment') ?? true;
    vibrate.value = prefs.getBool('${_prefix}vibrate') ?? false;
    others.value = prefs.getBool('${_prefix}others') ?? false;
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
  }

  void toggleGeneral(bool val) {
    generalNotifications.value = val;
    _saveSetting('general', val);
  }

  void toggleEvents(bool val) {
    events.value = val;
    _saveSetting('events', val);
  }

  void toggleMatches(bool val) {
    matches.value = val;
    _saveSetting('matches', val);
  }

  void toggleOffers(bool val) {
    offers.value = val;
    _saveSetting('offers', val);
  }

  void toggleNews(bool val) {
    news.value = val;
    _saveSetting('news', val);
  }

  void togglePayment(bool val) {
    payment.value = val;
    _saveSetting('payment', val);
  }

  void toggleVibrate(bool val) {
    vibrate.value = val;
    _saveSetting('vibrate', val);
  }

  void toggleOthers(bool val) {
    others.value = val;
    _saveSetting('others', val);
  }
}
