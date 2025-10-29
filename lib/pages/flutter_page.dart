import 'package:flutter/material.dart';
import 'universal_webview.dart';

class FlutterPage extends StatelessWidget {
  const FlutterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UniversalWebView(url: 'https://flutter.dev');
  }
}
