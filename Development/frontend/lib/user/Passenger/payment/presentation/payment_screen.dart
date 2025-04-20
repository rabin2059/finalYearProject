import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends ConsumerStatefulWidget {
  final String paymentUrl;

  const PaymentScreen({super.key, required this.paymentUrl});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late final WebViewController _controller;
  bool isRedirecting = false; // ✅ Prevent multiple redirects

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.paymentUrl));

    // ✅ Listen for Payment Success in WebView
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          if (url.contains("status=Completed") && !isRedirecting) {
            isRedirecting = true;
            _handlePaymentSuccess();
          }
        },
      ),
    );

    // ✅ Fallback: Check payment status every 5 seconds
    Future.delayed(const Duration(seconds: 5), checkPaymentStatus);
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
    } else {
      // Retry checking in 5 seconds if payment is not completed
      Future.delayed(const Duration(seconds: 5), checkPaymentStatus);
    }
  }

  /// **✅ Redirect on Payment Success**
  void _handlePaymentSuccess() {
    // ✅ Navigate to Booking Screen
    context.go('/navigation');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Processing Payment")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
