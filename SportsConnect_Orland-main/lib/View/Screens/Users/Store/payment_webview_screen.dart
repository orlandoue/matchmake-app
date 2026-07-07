import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/ticket_controller.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String checkoutUrl;

  /// Referencia de la preferencia creada server-side; se usa para consultar
  /// el estado real de la transacción al volver del checkout.
  final String externalReference;

  const PaymentWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.externalReference,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _title;

  @override
  void initState() {
    super.initState();
    print('🌐 [PaymentWebViewScreen] Initializing WebView');
    print('   Checkout URL: ${widget.checkoutUrl}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('🌐 [PaymentWebViewScreen] Page started: $url');
            if (mounted) setState(() => _isLoading = true);
            _handleRedirect(url);
          },
          onPageFinished: (url) {
            print('🌐 [PaymentWebViewScreen] Page finished: $url');
            if (mounted) {
              setState(() => _isLoading = false);
              _controller.getTitle().then((t) {
                if (mounted) setState(() => _title = t);
              });
            }
          },
          onWebResourceError: (error) {
            print(
                '🌐 [PaymentWebViewScreen] WebResource error: ${error.description} (code: ${error.errorCode})');
          },
          onNavigationRequest: (request) {
            print(
                '🌐 [PaymentWebViewScreen] Navigation request: ${request.url}');
            // Intercept deep link back URLs from Mercado Pago
            if (request.url.startsWith('sportsconnect://')) {
              _handleRedirect(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _handleRedirect(String url) {
    print('🔀 [PaymentWebViewScreen] Handling redirect: $url');

    if (url.startsWith('sportsconnect://payment/success') ||
        url.contains('collection_status=approved') ||
        url.contains('status=approved')) {
      print('✅ [PaymentWebViewScreen] Payment SUCCESS redirect detected');
      _onPaymentReturn();
    } else if (url.startsWith('sportsconnect://payment/failure') ||
        url.contains('status=rejected') ||
        url.contains('collection_status=rejected')) {
      print('❌ [PaymentWebViewScreen] Payment FAILURE detected');
      _onPaymentFailure();
    } else if (url.startsWith('sportsconnect://payment/pending') ||
        url.contains('status=pending') ||
        url.contains('collection_status=pending')) {
      print('⏳ [PaymentWebViewScreen] Payment PENDING detected');
      _onPaymentReturn();
    }
  }

  /// El redirect NO es prueba de pago: cerramos el WebView y dejamos que el
  /// controller verifique contra ticket_transactions (escrita por mp_webhook).
  void _onPaymentReturn() {
    if (!mounted) return;
    Get.back();
    TicketController.instance.verifyPurchase(widget.externalReference);
  }

  void _onPaymentFailure() {
    if (!mounted) return;
    Get.back();
    Get.snackbar(
      'Payment Failed',
      'Your payment was not completed. Please try again.',
      backgroundColor: Colors.red.shade600,
      colorText: kwhite,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: AppBar(
        backgroundColor: kpurple1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kwhite),
          onPressed: () {
            print('🌐 [PaymentWebViewScreen] User closed payment WebView');
            Get.back();
          },
        ),
        title: MyText(
          text: _title ?? 'Mercado Pago',
          size: 16,
          weight: FontWeight.w600,
          color: kwhite,
          maxLines: 1,
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: kwhite,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: kpurple1),
            ),
        ],
      ),
    );
  }
}
