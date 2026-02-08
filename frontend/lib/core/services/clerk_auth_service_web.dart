/// Web implementation for browser-specific functionality
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Get the web base URL for OAuth redirects
String getWebBaseUrl() {
  final uri = Uri.base;
  final port = uri.port;
  final hasNonStandardPort = port != 80 && port != 443;
  return '${uri.scheme}://${uri.host}${hasNonStandardPort ? ':$port' : ''}';
}

/// Redirect to URL in web browser
void redirectTo(String url) {
  html.window.location.href = url;
}
