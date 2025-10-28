import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class GooglePage extends StatefulWidget {
  const GooglePage({super.key});

  @override
  State<GooglePage> createState() => _GooglePageState();
}

class _GooglePageState extends State<GooglePage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // Register WebView platform implementation untuk web
    if (kIsWeb) {
      WebViewPlatform.instance ??= WebWebViewPlatform();
    }

    _controller = WebViewController()
      ..loadRequest(Uri.parse('https://www.google.com'));

    // Set JavaScript mode hanya jika tidak di web
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
