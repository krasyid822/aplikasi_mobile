import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FlutterPage extends StatelessWidget {
  const FlutterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://flutter.dev')),
    );
  }
}