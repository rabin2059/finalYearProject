import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class PaymentScreen extends ConsumerStatefulWidget {
  final String paymentUrl;

  const PaymentScreen({super.key, required this.paymentUrl});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late final WebViewController _controller;
  late Timer _timer;
  bool isRedirecting = false; // ✅ Prevent multiple redirects

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (String url) {
            if (url.contains("status=Completed") && !isRedirecting) {
              isRedirecting = true;
              _handlePaymentSuccess();
            }
          },
        ))
        ..loadRequest(Uri.parse(widget.paymentUrl));

      _timer = Timer.periodic(const Duration(seconds: 5), (_) => checkPaymentStatus());
    });
  }

  /// **✅ Backend Verification (Fallback)**
  Future<void> checkPaymentStatus() async {
    final response = await http.get(Uri.parse(
        "http://localhost:3089/api/v1/makePayment/?pidx=7SHNYUc594NSKmB8b2ho82"));

    final data = json.decode(response.body);

    if (data["paymentInfo"]["status"] == "Completed" &&
        mounted &&
        !isRedirecting) {
      isRedirecting = true;
      _handlePaymentSuccess();
    }
  }

  /// **✅ Redirect on Payment Success**
  void _handlePaymentSuccess() {
    _timer.cancel(); // Cancel the timer to prevent memory leaks
    // ✅ Navigate to Booking Screen
    context.go('/navigation');
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Processing Payment")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
