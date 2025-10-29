import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html';

class UniversalWebView extends StatefulWidget {
  final String url;

  const UniversalWebView({super.key, required this.url});

  @override
  State<UniversalWebView> createState() => _UniversalWebViewState();
}

class _UniversalWebViewState extends State<UniversalWebView> {
  bool _isLoading = true;
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    // Create a unique view factory name.
    _viewType = 'iframe-${widget.url}';

    final IFrameElement iFrameElement = IFrameElement()
      ..src = widget.url
      ..style.border = 'none'
      ..onLoad.listen((event) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => iFrameElement,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HtmlElementView(
          viewType: _viewType,
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
