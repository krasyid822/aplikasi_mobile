// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// Web-specific implementation
// This file is used when dart:html is available (web platform)

import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

void registerWebView(String viewType, String videoId) {
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final iframe = html.IFrameElement()
      ..src =
          'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
      ..allowFullscreen = true;
    return iframe;
  });
}
