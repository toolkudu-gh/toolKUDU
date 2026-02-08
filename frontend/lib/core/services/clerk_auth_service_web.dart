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

/// Wait for Clerk JS SDK to load and initialize
Future<bool> waitForClerk({Duration timeout = const Duration(seconds: 10)}) async {
  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < timeout) {
    // Check if Clerk global is available
    if (clerk != null) {
      try {
        // Load/initialize Clerk
        await clerk!.load().toDart;
        print('Clerk JS SDK loaded successfully');
        return true;
      } catch (e) {
        print('Error loading Clerk: $e');
        return false;
      }
    }

    // Also check the window.clerkLoaded flag
    if (clerkLoaded == true && clerk != null) {
      try {
        await clerk!.load().toDart;
        print('Clerk JS SDK loaded via clerkLoaded flag');
        return true;
      } catch (e) {
        print('Error loading Clerk after clerkLoaded: $e');
        return false;
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  print('Clerk JS SDK load timeout after ${timeout.inSeconds}s');
  return false;
}

/// Sign in with Google using Clerk JS SDK OAuth redirect
Future<void> clerkSignInWithGoogle(String redirectUrl) async {
  if (clerk == null) {
    throw Exception('Clerk JS SDK not loaded');
  }

  final params = <String, dynamic>{
    'strategy': 'oauth_google',
    'redirectUrl': redirectUrl,
    'redirectUrlComplete': redirectUrl,
  }.jsify();

  await clerk!.client!.signIn.authenticateWithRedirect(params as JSObject).toDart;
}

/// Get current session JWT token from Clerk JS SDK
Future<String?> getClerkSessionToken() async {
  if (clerk?.session == null) {
    print('No active Clerk session');
    return null;
  }

  try {
    final token = await clerk!.session!.getToken().toDart;
    final jwt = token.jwt;
    if (jwt != null && jwt.isNotEmpty) {
      print('Got JWT from Clerk session (length: ${jwt.length})');
      return jwt;
    }
    return null;
  } catch (e) {
    print('Error getting Clerk session token: $e');
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
    print('Error getting Clerk user: $e');
    return null;
  }
}

/// Check if there is an active Clerk session
bool hasClerkSession() {
  return clerk?.session != null;
}

/// Sign out using Clerk JS SDK
Future<void> clerkSignOut() async {
  if (clerk != null) {
    try {
      await clerk!.signOut().toDart;
      print('Clerk sign out successful');
    } catch (e) {
      print('Error signing out from Clerk: $e');
    }
  }
}
