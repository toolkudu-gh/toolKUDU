// Web implementation for browser-specific functionality
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js_interop';

import 'clerk_js_interop.dart';

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

/// Check if Clerk SDK failed to load from CDN
@JS('window.clerkLoadError')
external bool? get clerkLoadError;

/// Wait for Clerk JS SDK to load and initialize
Future<bool> waitForClerk({Duration timeout = const Duration(seconds: 20)}) async {
  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < timeout) {
    // Check if SDK failed to load from CDN (set by onerror handler in index.html)
    if (clerkLoadError == true) {
      print('[Clerk] SDK failed to load from CDN - check network/CSP');
      return false;
    }

    // Check if Clerk global is available
    if (clerk != null) {
      try {
        // Load/initialize Clerk
        await clerk!.load().toDart;
        print('[Clerk] SDK loaded and initialized successfully');
        return true;
      } catch (e) {
        print('[Clerk] Error initializing SDK: $e');
        return false;
      }
    }

    // Also check the window.clerkLoaded flag
    if (clerkLoaded == true && clerk != null) {
      try {
        await clerk!.load().toDart;
        print('[Clerk] SDK loaded via clerkLoaded flag');
        return true;
      } catch (e) {
        print('[Clerk] Error loading after clerkLoaded: $e');
        return false;
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  print('[Clerk] SDK load timeout after ${timeout.inSeconds}s');
  print('[Clerk] clerkLoaded=$clerkLoaded, clerkLoadError=$clerkLoadError, clerk=${clerk != null}');
  return false;
}

/// Sign in with Google using Clerk JS SDK
/// Uses authenticateWithRedirect directly for OAuth flow
Future<void> clerkSignInWithGoogle(String redirectUrl) async {
  if (clerk == null) {
    throw Exception('Clerk JS SDK not loaded');
  }

  if (clerk!.client == null) {
    throw Exception('Clerk client not available');
  }

  print('[Clerk] Starting Google OAuth sign-in...');
  print('[Clerk] Redirect URL: $redirectUrl');

  // Use authenticateWithRedirect directly on client.signIn
  // This is the recommended one-step OAuth approach
  final params = <String, dynamic>{
    'strategy': 'oauth_google',
    'redirectUrl': redirectUrl,
    'redirectUrlComplete': redirectUrl,
    'prompt': 'select_account',
  }.jsify() as JSObject;

  print('[Clerk] Calling authenticateWithRedirect (fire-and-forget)...');
  // Fire-and-forget: don't await. The SDK will redirect the browser.
  // Awaiting can cause GoRouter to react to the URL change before we
  // return control to the auth provider.
  clerk!.client!.signIn.authenticateWithRedirect(params).toDart.catchError((e) {
    print('[Clerk] authenticateWithRedirect error: $e');
  });
}

/// Get current session JWT token from Clerk JS SDK
Future<String?> getClerkSessionToken() async {
  if (clerk?.session == null) {
    print('[Clerk] No active session');
    return null;
  }

  try {
    final result = await clerk!.session!.getToken().toDart;
    if (result == null) {
      print('[Clerk] getToken() returned null');
      return null;
    }

    // Clerk JS SDK v5 returns the JWT string directly from getToken()
    // Try as JSString first (most common in v5)
    String? jwt;
    if (result.isA<JSString>()) {
      jwt = (result as JSString).toDart;
      print('[Clerk] getToken() returned string directly');
    } else {
      // Some versions return an object - try dartify and extract
      final dartified = result.dartify();
      if (dartified is String) {
        jwt = dartified;
        print('[Clerk] getToken() returned dartified string');
      } else if (dartified is Map) {
        jwt = dartified['jwt']?.toString();
        print('[Clerk] getToken() returned object with jwt property');
      } else {
        print('[Clerk] getToken() returned unexpected type: ${dartified.runtimeType}');
        // Last resort: stringify
        jwt = dartified?.toString();
      }
    }

    if (jwt != null && jwt.isNotEmpty && jwt.startsWith('ey')) {
      print('[Clerk] Got JWT from session (length: ${jwt.length})');
      return jwt;
    }
    final preview = jwt != null && jwt.length > 20 ? jwt.substring(0, 20) : jwt;
    print('[Clerk] getToken() returned non-JWT value: $preview');
    return null;
  } catch (e) {
    print('[Clerk] Error getting session token: $e');
    return null;
  }
}

/// Get current user data from Clerk JS SDK
Map<String, dynamic>? getClerkUser() {
  if (clerk?.user == null) {
    return null;
  }

  try {
    final user = clerk!.user!;
    final emails = user.emailAddresses.toDart;

    // Find primary email
    String? email;
    for (final e in emails) {
      if (e.id == user.primaryEmailAddressId) {
        email = e.emailAddress;
        break;
      }
    }

    // Fall back to first email if primary not found
    if (email == null && emails.isNotEmpty) {
      email = emails.first.emailAddress;
    }

    return {
      'id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': email,
      'imageUrl': user.imageUrl,
      'username': user.username,
    };
  } catch (e) {
    print('[Clerk] Error getting user: $e');
    return null;
  }
}

/// Check if there is an active Clerk session
bool hasClerkSession() {
  final hasSession = clerk?.session != null;
  print('[Clerk] hasClerkSession: $hasSession');
  return hasSession;
}

/// Sign out using Clerk JS SDK
Future<void> clerkSignOut() async {
  if (clerk != null) {
    try {
      await clerk!.signOut().toDart;
      print('[Clerk] Sign out successful');
    } catch (e) {
      print('[Clerk] Error signing out: $e');
    }
  }
}
