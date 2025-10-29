
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html';

class UniversalWebView extends StatelessWidget {
  final String url;

  const UniversalWebView({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    // Create a unique view factory name.
    final String viewType = 'iframe-$url';

    final IFrameElement iFrameElement = IFrameElement()
      ..src = url
      ..style.border = 'none';

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => iFrameElement,
    );

    return HtmlElementView(
      viewType: viewType,
    );
  }
}
