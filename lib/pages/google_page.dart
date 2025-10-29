import 'package:flutter/material.dart';
import 'universal_webview.dart';

class GooglePage extends StatelessWidget {
  const GooglePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UniversalWebView(url: 'https://www.google.com');
  }
}
