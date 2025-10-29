import 'package:flutter/material.dart';
import 'universal_webview.dart';

class GithubPage extends StatelessWidget {
  const GithubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const UniversalWebView(url: 'https://github.com');
  }
}
