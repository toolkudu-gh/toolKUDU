// Stub implementation for non-web platforms
// These functions are no-ops or return defaults on mobile platforms

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

/// Wait for Clerk JS SDK (not available on mobile)
Future<bool> waitForClerk({Duration timeout = const Duration(seconds: 10)}) async {
  // Clerk JS SDK only available on web
  return false;
}

/// Sign in with Google using Clerk JS SDK (not available on mobile)
Future<void> clerkSignInWithGoogle(String redirectUrl) async {
  // No-op on mobile - uses url_launcher flow instead
}

/// Get current session JWT token (not available on mobile via JS SDK)
Future<String?> getClerkSessionToken() async {
  // Clerk JS SDK only available on web
  return null;
}

/// Get current user data from Clerk JS SDK (not available on mobile)
Map<String, dynamic>? getClerkUser() {
  // Clerk JS SDK only available on web
  return null;
}

/// Check if there is an active Clerk session (not available on mobile)
bool hasClerkSession() {
  // Clerk JS SDK only available on web
  return false;
}

/// Sign out using Clerk JS SDK (no-op on mobile)
Future<void> clerkSignOut() async {
  // No-op on mobile platforms
}
