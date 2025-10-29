import 'package:flutter/material.dart';
import 'universal_webview.dart';

class PolmedPage extends StatelessWidget {
  const PolmedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UniversalWebView(url: 'https://www.polmed.ac.id');
  }
}
