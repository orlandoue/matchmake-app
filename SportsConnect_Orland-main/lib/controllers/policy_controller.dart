import 'package:get/get.dart';
import 'package:orland_sports/models/policy_model.dart';
import 'package:orland_sports/services/policy_service.dart';

class PolicyController extends GetxController {
  PolicyController({required this.slug});

  final String slug;
  final _policyService = PolicyService.instance;

  final Rxn<PolicyModel> policy = Rxn<PolicyModel>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPolicy();
  }

  Future<void> loadPolicy({bool forceRefresh = false}) async {
    if (isLoading.value) {
      return;
    }

    if (!forceRefresh && policy.value != null && errorMessage.value.isEmpty) {
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _policyService.getPolicyBySlug(slug);
      if (result == null) {
        policy.value = null;
        errorMessage.value = 'no_policy_available'.tr;
        return;
      }

      policy.value = result;
    } catch (_) {
      policy.value = null;
      errorMessage.value = 'failed_load_policy'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}
