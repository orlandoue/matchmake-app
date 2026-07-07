import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/services/mercadopago_service.dart';
import 'package:orland_sports/services/ticket_service.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:orland_sports/View/Screens/Users/Store/payment_webview_screen.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller for managing user tickets and payment flow.
///
/// Los pagos son 100% server-side: la Edge Function `create_preference` crea
/// el checkout (precios desde `ticket_products`) y `mp_webhook` acredita los
/// tickets. Este controller nunca modifica saldos por una compra: solo
/// observa `ticket_transactions` hasta que el webhook confirme `approved`.
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
  final RxBool isVerifyingPayment = false.obs;

  // Type of ticket being purchased
  final RxString purchasingTicketType = 'singles'.obs;

  /// Precios vigentes (ticket_type → CLP), cargados desde `ticket_products`.
  /// Solo para mostrar en la tienda: el cobro real lo calcula el servidor.
  final RxMap<String, double> ticketPrices =
      <String, double>{'singles': 500, 'doubles': 500}.obs;

  static const String currency = 'CLP';

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  double priceForType(String ticketType) => ticketPrices[ticketType] ?? 0;

  double get totalPrice =>
      selectedQuantity.value * priceForType(purchasingTicketType.value);

  @override
  void onInit() {
    super.onInit();
    _loadTicketBalance();
    _loadTicketPrices();
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

  Future<void> _loadTicketPrices() async {
    final prices = await _ticketService.getTicketPrices();
    if (prices.isNotEmpty) {
      ticketPrices.addAll(prices);
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

  /// Purchase tickets via Mercado Pago Checkout Pro (server-side preference).
  Future<void> purchaseTickets() async {
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
      final preference = await _mercadoPagoService.createPreference(
        ticketQuantity: quantity,
        ticketType: purchasingTicketType.value,
      );

      if (preference == null) {
        CustomToast.instance.showFailureToast(
          title: 'payment_error'.tr,
          message: 'could_not_initiate_payment'.tr,
        );
        return;
      }

      if (kIsWeb) {
        final url = Uri.parse(preference.initPoint);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          CustomToast.instance.showFailureToast(
            title: 'error'.tr,
            message: 'could_not_open_url'.tr,
          );
        }
      } else {
        Get.to(() => PaymentWebViewScreen(
              checkoutUrl: preference.initPoint,
              externalReference: preference.externalReference,
            ));
      }
    } catch (_) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'payment_failed'.tr,
      );
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Verifica el resultado de una compra tras volver del checkout.
  ///
  /// No acredita nada localmente: consulta `ticket_transactions` (que solo
  /// escribe el webhook) hasta ver `approved`, con un spinner bloqueante
  /// "Verificando pago...". Timeout → mensaje de pendiente.
  Future<void> verifyPurchase(String externalReference) async {
    if (isVerifyingPayment.value) return;
    isVerifyingPayment.value = true;
    _showVerifyingDialog();

    const pollInterval = Duration(seconds: 2);
    const maxAttempts = 45; // ~90 segundos

    try {
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final status =
            await _mercadoPagoService.getTransactionStatus(externalReference);

        if (status == 'approved') {
          await _loadTicketBalance();
          _closeVerifyingDialog();
          CustomToast.instance.showSuccessToast(
            title: 'purchase_successful'.tr,
            message: 'payment_confirmed'.tr,
          );
          return;
        }

        if (status == 'rejected' ||
            status == 'cancelled' ||
            status == 'credit_failed') {
          _closeVerifyingDialog();
          CustomToast.instance.showFailureToast(
            title: 'payment_error'.tr,
            message: 'payment_not_confirmed'.tr,
          );
          return;
        }

        // pending / in_process / aún sin webhook → seguir esperando
        await Future.delayed(pollInterval);
      }

      // Timeout: el webhook aún no confirma. No acreditar nada.
      _closeVerifyingDialog();
      CustomToast.instance.showWarningToast(
        title: 'payment_pending'.tr,
        message: 'payment_pending_message'.tr,
      );
    } catch (_) {
      _closeVerifyingDialog();
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'payment_not_confirmed'.tr,
      );
    } finally {
      isVerifyingPayment.value = false;
    }
  }

  void _showVerifyingDialog() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: kwhite,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: kpurple1),
                const SizedBox(height: 20),
                MyText(
                  text: 'verifying_payment'.tr,
                  size: 16,
                  weight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _closeVerifyingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
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
      final success =
          await _ticketService.useTicket(userId, matchId, ticketType);
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
  Future<bool> refundTicketForUser(
      String matchId, String userId, String ticketType) async {
    try {
      isLoading.value = true;
      final success =
          await _ticketService.refundTicket(userId, matchId, ticketType);
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
