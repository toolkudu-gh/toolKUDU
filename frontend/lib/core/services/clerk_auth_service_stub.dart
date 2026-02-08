/// Stub implementation for non-web platforms
/// These functions are no-ops on mobile platforms

import '../config/app_config.dart';

/// Get the web base URL for OAuth redirects
String getWebBaseUrl() {
  return AppConfig.webBaseUrl;
}

/// Redirect to URL (no-op on mobile - uses url_launcher instead)
void redirectTo(String url) {
  // No-op on mobile platforms
  // Mobile uses url_launcher in the main service
}
