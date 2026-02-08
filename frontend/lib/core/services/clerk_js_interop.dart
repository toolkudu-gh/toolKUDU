// Dart-JS interop bindings for Clerk JS SDK
// This file provides typed access to Clerk's browser SDK methods
@JS()
library;

import 'dart:js_interop';

/// Global Clerk instance (available after SDK loads)
@JS('Clerk')
external ClerkJS? get clerk;

/// Check if Clerk SDK has loaded
@JS('window.clerkLoaded')
external bool? get clerkLoaded;

/// Main Clerk JS SDK interface
extension type ClerkJS._(JSObject _) implements JSObject {
  /// Load the Clerk SDK (must be called before using other methods)
  external JSPromise<JSAny?> load();

  /// The Clerk client for sign-in/sign-up operations
  external ClerkClient? get client;

  /// The current active session (null if not signed in)
  external ClerkSession? get session;

  /// The current user (null if not signed in)
  external ClerkUser? get user;

  /// Sign out the current user
  external JSPromise<JSAny?> signOut();

  /// Add a listener for session changes
  external void addListener(JSFunction callback);
}

/// Clerk client for authentication operations
extension type ClerkClient._(JSObject _) implements JSObject {
  /// Sign-in resource for creating sign-in attempts
  external ClerkSignIn get signIn;

  /// Sign-up resource for creating sign-up attempts
  external ClerkSignUp get signUp;
}

/// Sign-in resource
extension type ClerkSignIn._(JSObject _) implements JSObject {
  /// Create a new sign-in attempt
  external JSPromise<JSAny?> create(JSObject params);

  /// Authenticate with OAuth redirect
  external JSPromise<JSAny?> authenticateWithRedirect(JSObject params);
}

/// Sign-up resource
extension type ClerkSignUp._(JSObject _) implements JSObject {
  /// Create a new sign-up attempt
  external JSPromise<JSAny?> create(JSObject params);

  /// Authenticate with OAuth redirect
  external JSPromise<JSAny?> authenticateWithRedirect(JSObject params);
}

/// Active session
extension type ClerkSession._(JSObject _) implements JSObject {
  /// Session ID
  external String get id;

  /// Session status
  external String get status;

  /// Get a fresh JWT token for this session
  external JSPromise<ClerkToken> getToken();
}

/// JWT token from getToken()
extension type ClerkToken._(JSObject _) implements JSObject {
  /// The JWT string
  external String? get jwt;
}

/// Clerk user object
extension type ClerkUser._(JSObject _) implements JSObject {
  /// User's Clerk ID
  external String get id;

  /// User's first name
  external String? get firstName;

  /// User's last name
  external String? get lastName;

  /// User's profile image URL
  external String? get imageUrl;

  /// User's username
  external String? get username;

  /// Array of email addresses
  external JSArray<ClerkEmail> get emailAddresses;

  /// ID of the primary email address
  external String? get primaryEmailAddressId;
}

/// Email address object
extension type ClerkEmail._(JSObject _) implements JSObject {
  /// Email address ID
  external String get id;

  /// The actual email address
  external String get emailAddress;
}
