import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class PaymentScreen extends ConsumerStatefulWidget {
  final String paymentUrl;
  final String pidx;

  const PaymentScreen({super.key, required this.paymentUrl, required this.pidx});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late final WebViewController _controller;
  late Timer _timer;
  bool isRedirecting = false; 

  @override
  void initState() {
    super.initState();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => checkPaymentStatus());
    });
  }

  Future<void> checkPaymentStatus() async {
    final response = await http.get(Uri.parse(
        "http://localhost:3089/api/v1/makePayment/?pidx=${widget.pidx}"));

    final data = json.decode(response.body);

    if (data["paymentInfo"]["status"] == "Completed" &&
        mounted &&
        !isRedirecting) {
      isRedirecting = true;
      _handlePaymentSuccess();
    }
  }

  void _handlePaymentSuccess() {
    _timer.cancel(); 
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
