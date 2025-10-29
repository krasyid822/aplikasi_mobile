
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UniversalWebView extends StatelessWidget {
  final String url;

  const UniversalWebView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return WebViewWidget(controller: controller);
  }
}
