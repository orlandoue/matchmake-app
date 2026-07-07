import 'dart:ui';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends GetxController {
  final _box = GetStorage();
  static const _key = 'language_code';

  final selectedLanguage = 'es'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    final savedLang = _box.read(_key) ?? 'es';
    selectedLanguage.value = savedLang;
    _updateLocale(savedLang);
  }

  void changeLanguage(String langCode) {
    selectedLanguage.value = langCode;
    _box.write(_key, langCode);
    _updateLocale(langCode);
  }

  void _updateLocale(String langCode) {
    switch (langCode) {
      case 'es':
        Get.updateLocale(const Locale('es', 'ES'));
        break;
      case 'en':
      default:
        Get.updateLocale(const Locale('en', 'US'));
        break;
    }
  }

  bool get isEnglish => selectedLanguage.value == 'en';
  bool get isSpanish => selectedLanguage.value == 'es';
}
