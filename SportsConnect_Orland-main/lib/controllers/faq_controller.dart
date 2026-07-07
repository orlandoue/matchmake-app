import 'package:get/get.dart';
import 'package:orland_sports/models/faq_model.dart';
import 'package:orland_sports/services/faq_service.dart';

class FaqController extends GetxController {
  static FaqController get instance => Get.find<FaqController>();

  final _faqService = FaqService.instance;

  final RxList<FaqModel> faqs = <FaqModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadFaqs();
  }

  Future<void> loadFaqs() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _faqService.getActiveFaqs();
      faqs.assignAll(result);
    } catch (e) {
      faqs.clear();
      errorMessage.value = 'failed_load_faqs'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}
