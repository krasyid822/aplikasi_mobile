import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GooglePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.google.com')),
    );
  }
}