import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:orland_sports/const/mercadopago_config.dart';
import 'package:orland_sports/services/mercadopago_service.dart';
import 'package:orland_sports/services/ticket_service.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:orland_sports/View/Screens/Users/Store/payment_webview_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller for managing user tickets and payment flow
class TicketController extends GetxController {
  static TicketController get instance => Get.find<TicketController>();

  final _ticketService = TicketService.instance;
  final _mercadoPagoService = MercadoPagoService.instance;

  // Observables
  final RxInt singlesBalance = 0.obs;
  final RxInt doublesBalance = 0.obs;
  final RxInt selectedQuantity = 1.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPurchasing = false.obs;
  
  // Type of ticket being purchased
  final RxString purchasingTicketType = 'singles'.obs;

  // Pending purchase info (to complete after payment redirect)
  int _pendingQuantity = 0;

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;
  String? get currentUserEmail =>
      Supabase.instance.client.auth.currentUser?.email;

  double get totalPrice =>
      selectedQuantity.value *
      MercadoPagoConfig.priceForType(purchasingTicketType.value);

  @override
  void onInit() {
    super.onInit();
    _loadTicketBalance();
  }

  /// Load the current user's ticket balance
  Future<void> _loadTicketBalance() async {
    final userId = currentUserId;
    if (userId == null) return;

    await _ticketService.ensureTicketRecord(userId);
    final record = await _ticketService.getTicketRecord(userId);
    if (record != null) {
      singlesBalance.value = record.singlesQuantity;
      doublesBalance.value = record.doublesQuantity;
    } else {
      singlesBalance.value = 0;
      doublesBalance.value = 0;
    }
  }

  /// Refresh ticket balance (public method for pull-to-refresh, etc.)
  Future<void> refreshBalance() async {
    await _loadTicketBalance();
  }

  /// Increment selected quantity
  void incrementQuantity() {
    if (selectedQuantity.value < 99) {
      selectedQuantity.value++;
    }
  }

  /// Decrement selected quantity
  void decrementQuantity() {
    if (selectedQuantity.value > 1) {
      selectedQuantity.value--;
    }
  }

  /// Check if user has at least 1 ticket of a specific type
  bool hasTickets(String type) {
    if (type == 'singles') {
       return singlesBalance.value > 0;
    } else {
       return doublesBalance.value > 0;
    }
  }

  /// Purchase tickets via Mercado Pago Checkout Pro
  Future<void> purchaseTickets() async {
    final userId = currentUserId;
    final email = currentUserEmail;
    print('🎫 [TicketController.purchaseTickets] Starting purchase flow');
    print('   userId: $userId');
    print('   email: $email');

    if (userId == null || email == null) {
      print('❌ [TicketController.purchaseTickets] Missing userId or email');
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_login_purchase'.tr,
      );
      return;
    }

    try {
      isPurchasing.value = true;

      final quantity = selectedQuantity.value;
      print('🎫 [TicketController.purchaseTickets] Quantity: $quantity');

      // Create Mercado Pago preference
      print(
          '🎫 [TicketController.purchaseTickets] Creating Mercado Pago preference...');
      final preference = await _mercadoPagoService.createPreference(
        ticketQuantity: quantity,
        ticketType: purchasingTicketType.value,
        userId: userId,
        userEmail: email,
      );

      if (preference == null) {
        print(
            '❌ [TicketController.purchaseTickets] Preference creation failed (returned null)');
        CustomToast.instance.showFailureToast(
          title: 'payment_error'.tr,
          message: 'could_not_initiate_payment'.tr,
        );
        return;
      }

      print(
          '✅ [TicketController.purchaseTickets] Preference created successfully');
      print('   Preference ID: ${preference.id}');
      print('   Init Point: ${preference.initPoint}');
      print('   Sandbox Mode: ${MercadoPagoConfig.useSandbox}');

      // Store pending purchase info
      _pendingQuantity = quantity;

      // Open Mercado Pago checkout in browser
      final checkoutUrl = _mercadoPagoService.getCheckoutUrl(preference);
      print('🎫 [TicketController.purchaseTickets] Checkout URL: $checkoutUrl');

      if (kIsWeb) {
        print('🎫 [TicketController.purchaseTickets] Launching external URL for Web...');
        final url = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          CustomToast.instance.showFailureToast(
            title: 'error'.tr,
            message: 'could_not_open_url'.tr ?? 'Could not open URL',
          );
        }
      } else {
        // Open Mercado Pago checkout in a WebView inside the app
        print('🎫 [TicketController.purchaseTickets] Opening WebView payment screen...');
        Get.to(() => PaymentWebViewScreen(
              checkoutUrl: checkoutUrl,
              ticketQuantity: quantity,
            ));
        print('✅ [TicketController.purchaseTickets] WebView opened successfully');
      }
    } catch (e) {
      print('❌ [TicketController.purchaseTickets] Exception: $e');
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'payment_failed'.tr,
      );
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Complete the purchase after user returns from Mercado Pago
  /// Called when the app receives the deep link callback
  Future<void> completePurchase({String? paymentId}) async {
    final userId = currentUserId;
    if (userId == null) return;

    final quantity = _pendingQuantity;
    if (quantity <= 0) return;

    try {
      isLoading.value = true;

      // Add tickets to balance
      final ticketType = purchasingTicketType.value;
      final success = await _ticketService.addTickets(userId, quantity, ticketType);
      if (success) {
        // Record the transaction
        await _ticketService.recordPurchaseTransaction(
          userId: userId,
          quantity: quantity,
          ticketType: ticketType,
          amount: quantity * MercadoPagoConfig.priceForType(ticketType),
          currency: MercadoPagoConfig.currency,
          mercadopagoPaymentId: paymentId,
          paymentStatus: 'approved',
        );

        await _loadTicketBalance();

        CustomToast.instance.showSuccessToast(
          title: 'purchase_successful'.tr,
          message: 'tickets_added'.trParams({'quantity': '$quantity'}),
        );
      } else {
        CustomToast.instance.showFailureToast(
          title: 'error'.tr,
          message: 'failed_add_tickets'.tr,
        );
      }
    } finally {
      _pendingQuantity = 0;
      isLoading.value = false;
    }
  }

  /// Subscribe to VIP Plan (Dummy for MercadoPago Preapproval)
  Future<void> subscribeToPlan(String planName, double price) async {
    isPurchasing.value = true;
    try {
      // Dummy logic to simulate subscription
      await Future.delayed(const Duration(seconds: 2));
      CustomToast.instance.showSuccessToast(
        title: 'Suscripción Exitosa',
        message: 'Te has suscrito al plan: $planName',
      );
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'Error de Suscripción',
        message: 'No se pudo completar la suscripción.',
      );
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Simulate a successful purchase (for testing when deep links aren't set up)
  Future<void> simulatePurchase() async {
    final userId = currentUserId;
    if (userId == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_login_purchase'.tr,
      );
      return;
    }

    try {
      isPurchasing.value = true;
      final quantity = selectedQuantity.value;
      final ticketType = purchasingTicketType.value;
      final amount = quantity * MercadoPagoConfig.priceForType(ticketType);

      // Create preference to validate with Mercado Pago
      final preference = await _mercadoPagoService.createPreference(
        ticketQuantity: quantity,
        ticketType: ticketType,
        userId: userId,
        userEmail: currentUserEmail ?? '',
      );

      if (preference == null) {
        CustomToast.instance.showFailureToast(
          title: 'payment_error'.tr,
          message: 'could_not_connect_payment'.tr,
        );
        return;
      }

      // Add tickets
      final success = await _ticketService.addTickets(userId, quantity, ticketType);
      if (success) {
        await _ticketService.recordPurchaseTransaction(
          userId: userId,
          quantity: quantity,
          ticketType: ticketType,
          amount: amount,
          currency: MercadoPagoConfig.currency,
          mercadopagoPaymentId: preference.id,
          paymentStatus: 'approved',
        );

        await _loadTicketBalance();

        CustomToast.instance.showSuccessToast(
          title: 'purchase_successful'.tr,
          message: 'tickets_added'.trParams({'quantity': '$quantity'}),
        );
      }
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'purchase_failed'.tr,
      );
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Use a ticket for a match - returns true if successful
  Future<bool> useTicketForMatch(String matchId, String ticketType) async {
    final userId = currentUserId;
    if (userId == null) return false;

    if (!hasTickets(ticketType)) {
      CustomToast.instance.showWarningToast(
        title: 'no_tickets'.tr,
        message: 'need_ticket_to_play'.tr,
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _ticketService.useTicket(userId, matchId, ticketType);
      if (success) {
        await _loadTicketBalance();
        return true;
      } else {
        CustomToast.instance.showFailureToast(
          title: 'error'.tr,
          message: 'failed_use_ticket'.tr,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Refund ticket (used when match is cancelled or invitation rejected)
  Future<bool> refundTicketForUser(String matchId, String userId, String ticketType) async {
    try {
      isLoading.value = true;
      final success = await _ticketService.refundTicket(userId, matchId, ticketType);
      if (success) {
        // If it's the current user, refresh the balance state
        if (userId == currentUserId) {
          await _loadTicketBalance();
        }
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }
}
