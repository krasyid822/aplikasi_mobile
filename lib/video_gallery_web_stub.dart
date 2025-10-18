// Stub implementation for non-web platforms
// This file is used when dart:html is not available

void registerWebView(String viewType, String videoId) {
  throw UnsupportedError('Web views are not supported on this platform');
}
