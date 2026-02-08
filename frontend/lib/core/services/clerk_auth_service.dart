import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../models/user.dart';

// Conditional import for web
import 'clerk_auth_service_stub.dart'
    if (dart.library.html) 'clerk_auth_service_web.dart' as platform;

/// Clerk Authentication Service
/// Handles authentication via Clerk's Frontend API
class ClerkAuthService {
  final FlutterSecureStorage storage;
  final Dio _clerkApi;
  final Dio _backendApi;

  static const String _sessionTokenKey = 'clerk_session_token';
  static const String _userDataKey = 'clerk_user_data';
  static const String _pendingEmailKey = 'clerk_pending_email';

  // Clerk Frontend API base URL (extracted from publishable key)
  String get _clerkFrontendApi {
    // pk_test_Y2VydGFpbi1ha2l0YS02NC5jbGVyay5hY2NvdW50cy5kZXYk
    // Decode: certain-akita-64.clerk.accounts.dev (with trailing $)
    try {
      final keyPart = AppConfig.clerkPublishableKey
          .replaceFirst('pk_test_', '')
          .replaceFirst('pk_live_', '');
      var decoded = utf8.decode(base64.decode(keyPart));
      // Remove trailing $ that Clerk adds to the encoded domain
      if (decoded.endsWith('\$')) {
        decoded = decoded.substring(0, decoded.length - 1);
      }
      return 'https://$decoded';
    } catch (e) {
      return 'https://certain-akita-64.clerk.accounts.dev';
    }
  }

  // Clerk Account Portal URL (for hosted sign-in pages)
  String get _clerkAccountPortal {
    // Account Portal uses accounts.dev domain (not clerk.accounts.dev)
    // Format: https://<instance>.accounts.dev
    try {
      final keyPart = AppConfig.clerkPublishableKey
          .replaceFirst('pk_test_', '')
          .replaceFirst('pk_live_', '');
      var decoded = utf8.decode(base64.decode(keyPart));
      if (decoded.endsWith('\$')) {
        decoded = decoded.substring(0, decoded.length - 1);
      }
      // Convert from clerk.accounts.dev to accounts.dev
      // certain-akita-64.clerk.accounts.dev -> certain-akita-64.accounts.dev
      final instance = decoded.split('.').first; // certain-akita-64
      return 'https://$instance.accounts.dev';
    } catch (e) {
      return 'https://certain-akita-64.accounts.dev';
    }
  }

  /// Web base URL for OAuth redirects
  String get _webBaseUrl {
    return platform.getWebBaseUrl();
  }

  ClerkAuthService({required this.storage})
      : _clerkApi = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        )),
        _backendApi = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ));

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await storage.read(key: _sessionTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Get current session token
  Future<String?> getSessionToken() async {
    return await storage.read(key: _sessionTokenKey);
  }

  /// Get stored tokens map for compatibility
  Future<Map<String, String>?> getTokens() async {
    final sessionToken = await storage.read(key: _sessionTokenKey);
    if (sessionToken == null) return null;
    return {
      'accessToken': sessionToken,
      'sessionToken': sessionToken,
    };
  }

  /// Save session data
  Future<void> _saveSession({
    required String sessionToken,
    required Map<String, dynamic> userData,
  }) async {
    await storage.write(key: _sessionTokenKey, value: sessionToken);
    await storage.write(key: _userDataKey, value: jsonEncode(userData));

    // Update backend API headers
    _backendApi.options.headers['Authorization'] = 'Bearer $sessionToken';
  }

  /// Clear session data
  Future<void> clearSession() async {
    await storage.delete(key: _sessionTokenKey);
    await storage.delete(key: _userDataKey);
    await storage.delete(key: _pendingEmailKey);
    _backendApi.options.headers.remove('Authorization');
  }

  /// Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    try {
      // Create sign-up with Clerk
      final response = await _clerkApi.post(
        '$_clerkFrontendApi/v1/sign_ups',
        data: {
          'email_address': email,
          'password': password,
          'username': username,
          if (displayName != null) 'first_name': displayName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Check if email verification is required
        if (data['status'] == 'missing_requirements') {
          await storage.write(key: _pendingEmailKey, value: email);
          return {
            'success': true,
            'requiresVerification': true,
            'signUpId': data['id'],
            'message': 'Please check your email for verification code',
          };
        }

        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'error': 'Sign up failed',
      };
    } on DioException catch (e) {
      return _handleDioError(e, 'Sign up failed');
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify email with code
  Future<Map<String, dynamic>> verifyEmail(String code) async {
    try {
      final email = await storage.read(key: _pendingEmailKey);
      if (email == null) {
        return {'success': false, 'error': 'No pending verification'};
      }

      // Attempt verification via Clerk
      final response = await _clerkApi.post(
        '$_clerkFrontendApi/v1/sign_ups/verify',
        data: {
          'code': code,
          'strategy': 'email_code',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'complete') {
          // Get session from response
          final sessionToken =
              data['created_session_id'] ?? data['session_token'];
          if (sessionToken != null) {
            await _saveSession(
              sessionToken: sessionToken,
              userData: data['user'] ?? {},
            );
            await _syncUserWithBackend();
          }
          await storage.delete(key: _pendingEmailKey);
          return {'success': true};
        }
      }

      return {'success': false, 'error': 'Verification failed'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Verification failed');
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      // Create sign-in with Clerk
      final response = await _clerkApi.post(
        '$_clerkFrontendApi/v1/sign_ins',
        data: {
          'identifier': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['status'] == 'complete') {
          final sessionToken =
              data['created_session_id'] ?? data['session_token'];
          final userData = data['user'] ?? {'email': email};

          if (sessionToken == null || (sessionToken as String).isEmpty) {
            return {
              'success': false,
              'error': 'No valid session token received from server',
            };
          }

          await _saveSession(
            sessionToken: sessionToken,
            userData: userData,
          );

          await _syncUserWithBackend();

          return {
            'success': true,
            'accessToken': sessionToken,
            'user': userData,
          };
        }

        // Check if verification is needed
        if (data['status'] == 'needs_first_factor' ||
            data['status'] == 'needs_second_factor') {
          await storage.write(key: _pendingEmailKey, value: email);
          return {
            'success': false,
            'requiresVerification': true,
            'error': 'Please verify your email',
          };
        }
      }

      return {'success': false, 'error': 'Invalid email or password'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Sign in failed');
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign in with Google - redirects to Clerk's Account Portal sign-in page
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final redirectUrl = Uri.encodeComponent('$_webBaseUrl/auth/callback');

      // Use Clerk's Account Portal hosted sign-in page
      // Format: https://<instance>.accounts.dev/sign-in?redirect_url=<url>
      final clerkSignInUrl = '$_clerkAccountPortal/sign-in'
          '?redirect_url=$redirectUrl';

      // For web: redirect to Clerk hosted sign-in
      if (kIsWeb) {
        platform.redirectTo(clerkSignInUrl);
        return {'success': true, 'redirecting': true};
      }

      // For mobile: use url_launcher
      final uri = Uri.parse(clerkSignInUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return {'success': true, 'redirecting': true};
      }

      return {
        'success': false,
        'error': 'Could not open browser for sign-in',
      };
    } catch (e) {
      return {'success': false, 'error': 'Google sign-in failed: $e'};
    }
  }

  /// Handle OAuth callback - called after redirect from Clerk
  Future<Map<String, dynamic>> handleOAuthCallback({
    String? code,
    String? sessionId,
    String? sessionToken,
    String? handshakeToken,
  }) async {
    try {
      String? jwt;
      Map<String, dynamic> userData = {};

      print('OAuth callback received - sessionToken: ${sessionToken?.substring(0, 10) ?? 'null'}..., '
          'handshake: ${handshakeToken != null ? 'present' : 'null'}, '
          'sessionId: $sessionId');

      // Priority 1: If handshake token exists, extract session JWT from it
      // This is the most reliable method as it contains the actual session cookie
      if (handshakeToken != null && handshakeToken.isNotEmpty) {
        try {
          final extractedJwt = _extractSessionFromHandshake(handshakeToken);
          if (extractedJwt != null && extractedJwt.startsWith('ey')) {
            jwt = extractedJwt;
            print('Using JWT extracted from handshake');
          }
        } catch (e) {
          print('Failed to decode handshake token: $e');
        }
      }

      // Priority 2: If session token looks like a JWT, use it directly
      if (jwt == null && sessionToken != null && sessionToken.startsWith('ey')) {
        jwt = sessionToken;
        print('Using session token as JWT directly');
      }

      // Priority 3: If session token is a dev token (dvb_...), try to get JWT via Clerk API
      if (jwt == null && sessionToken != null && sessionToken.startsWith('dvb_')) {
        print('Dev token detected, attempting to get JWT from Clerk API');
        try {
          // The dvb_ token can be used as a session identifier
          final tokenResponse = await _clerkApi.post(
            '$_clerkFrontendApi/v1/client/sessions/$sessionToken/tokens',
          );
          if (tokenResponse.statusCode == 200) {
            jwt = tokenResponse.data['jwt'] as String?;
            print('Got JWT from dev token API');
          }
        } catch (e) {
          print('Failed to get JWT from dev token: $e');
        }
      }

      // Priority 4: If we have a session ID, get the JWT from Clerk
      if (jwt == null && sessionId != null && sessionId.isNotEmpty) {
        print('Attempting to get JWT from session ID: $sessionId');
        try {
          final tokenResponse = await _clerkApi.post(
            '$_clerkFrontendApi/v1/sessions/$sessionId/tokens',
          );
          if (tokenResponse.statusCode == 200) {
            jwt = tokenResponse.data['jwt'] as String?;
            print('Got JWT from session ID');
          }
        } catch (e) {
          print('Failed to get JWT from session: $e');
        }

        // Also try to get user data from session
        try {
          final sessionResponse = await _clerkApi.get(
            '$_clerkFrontendApi/v1/sessions/$sessionId',
          );
          if (sessionResponse.statusCode == 200) {
            userData = sessionResponse.data['user'] as Map<String, dynamic>? ?? {};
          }
        } catch (e) {
          print('Failed to get session details: $e');
        }
      }

      // Priority 5: Last resort - use session token as-is
      if (jwt == null && sessionToken != null && sessionToken.isNotEmpty) {
        print('Using session token as-is (last resort): ${sessionToken.substring(0, 10)}...');
        jwt = sessionToken;
      }

      if (jwt == null || jwt.isEmpty) {
        print('OAuth callback failed: No JWT obtained');
        return {
          'success': false,
          'error': 'Could not obtain authentication token from Clerk',
        };
      }

      print('OAuth callback success - saving session with JWT');
      await _saveSession(
        sessionToken: jwt,
        userData: userData,
      );

      // Sync with backend to get/create user
      final syncResult = await _syncUserWithBackend();

      return {
        'success': true,
        'accessToken': jwt,
        'user': syncResult ?? userData,
        'isNewUser': syncResult?['isNewUser'] ?? false,
      };
    } on DioException catch (e) {
      print('OAuth callback DioException: ${e.message}');
      return _handleDioError(e, 'OAuth callback failed');
    } catch (e) {
      print('OAuth callback error: $e');
      return {'success': false, 'error': 'OAuth callback failed: $e'};
    }
  }

  /// Decode URL-safe base64 (used in JWTs)
  /// Handles both standard and URL-safe base64 encoding
  String _decodeBase64Url(String input) {
    // Replace URL-safe characters with standard base64 characters
    String normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    // Add padding if needed
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    return utf8.decode(base64.decode(normalized));
  }

  /// Extract session JWT from Clerk handshake token
  /// The handshake JWT contains a 'handshake' claim with cookie instructions
  /// like: ["__session=eyJ...; Path=/; ..."]
  String? _extractSessionFromHandshake(String handshakeToken) {
    try {
      final parts = handshakeToken.split('.');
      if (parts.length < 2) {
        print('Handshake token has invalid format: ${parts.length} parts');
        return null;
      }

      // Decode the JWT payload (URL-safe base64)
      final payloadString = _decodeBase64Url(parts[1]);
      final payload = jsonDecode(payloadString) as Map<String, dynamic>;

      // The handshake claim contains an array of cookie strings
      final handshake = payload['handshake'] as List?;
      if (handshake == null) {
        print('No handshake claim found in token');
        return null;
      }

      // Find the __session cookie
      for (final cookie in handshake) {
        final cookieStr = cookie.toString();
        if (cookieStr.startsWith('__session=')) {
          // Extract the JWT value (before the first semicolon)
          final value = cookieStr.substring('__session='.length);
          final semicolonIndex = value.indexOf(';');
          final jwt = semicolonIndex > 0 ? value.substring(0, semicolonIndex) : value;
          print('Extracted session JWT from handshake (length: ${jwt.length})');
          return jwt;
        }
      }

      print('No __session cookie found in handshake. Cookies: ${handshake.length}');
      return null;
    } catch (e) {
      print('Error extracting session from handshake: $e');
      return null;
    }
  }

  /// Request magic link / email code
  Future<Map<String, dynamic>> requestMagicLink(String email) async {
    try {
      // Create sign-in with email code strategy
      final response = await _clerkApi.post(
        '$_clerkFrontendApi/v1/sign_ins',
        data: {
          'identifier': email,
          'strategy': 'email_code',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await storage.write(key: _pendingEmailKey, value: email);
        return {
          'success': true,
          'message': 'Verification code sent to your email',
        };
      }

      return {'success': false, 'error': 'Failed to send code'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Failed to send code');
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify magic link code
  Future<Map<String, dynamic>> verifyMagicLinkCode(String code) async {
    try {
      final email = await storage.read(key: _pendingEmailKey);
      if (email == null) {
        return {'success': false, 'error': 'No pending verification'};
      }

      // Verify the code
      final response = await _clerkApi.post(
        '$_clerkFrontendApi/v1/sign_ins/verify',
        data: {
          'code': code,
          'strategy': 'email_code',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['status'] == 'complete') {
          final sessionToken = data['created_session_id'] ?? data['session_token'];
          final userData = data['user'] ?? {'email': email};

          if (sessionToken == null || (sessionToken as String).isEmpty) {
            return {
              'success': false,
              'error': 'No valid session token received from server',
            };
          }

          await _saveSession(sessionToken: sessionToken, userData: userData);
          await _syncUserWithBackend();
          await storage.delete(key: _pendingEmailKey);

          return {
            'success': true,
            'accessToken': sessionToken,
            'user': userData,
          };
        }
      }

      return {'success': false, 'error': 'Invalid code'};
    } on DioException catch (e) {
      return _handleDioError(e, 'Verification failed');
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Resend verification code
  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    return await requestMagicLink(email);
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      final sessionToken = await getSessionToken();
      if (sessionToken != null) {
        await _clerkApi.delete(
          '$_clerkFrontendApi/v1/sessions/$sessionToken',
        );
      }
    } catch (_) {}

    await clearSession();
  }

  /// Get current user - fetches from backend using Clerk session
  Future<User?> getCurrentUser() async {
    try {
      final sessionToken = await getSessionToken();
      if (sessionToken == null) return null;

      // Fetch from backend with Clerk token
      _backendApi.options.headers['Authorization'] = 'Bearer $sessionToken';

      try {
        final response = await _backendApi.get('/api/users/me');

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          // Update stored user data
          await storage.write(key: _userDataKey, value: jsonEncode(data));

          return User(
            id: data['id']?.toString() ?? '',
            username: data['username'] ?? 'user',
            email: data['email']?.toString() ?? '',
            displayName: data['displayName'] ?? data['display_name'],
            avatarUrl: data['avatarUrl'] ?? data['avatar_url'],
            bio: data['bio'],
            toolboxCount: data['toolboxCount'] ?? 0,
            toolCount: data['toolCount'] ?? 0,
          );
        }
      } catch (e) {
        print('Failed to fetch user from backend: $e');
        // Fall through to local data
      }

      // Fallback to stored local data
      final userData = await storage.read(key: _userDataKey);
      if (userData == null) return null;

      final data = jsonDecode(userData) as Map<String, dynamic>;

      return User(
        id: data['id']?.toString() ??
            data['clerk_id']?.toString() ??
            'user_${data['email']?.hashCode}',
        username:
            data['username'] ?? data['email']?.toString().split('@').first ?? 'user',
        email: data['email']?.toString() ?? '',
        displayName:
            data['displayName'] ?? data['first_name'] ?? data['display_name'],
        avatarUrl:
            data['avatarUrl'] ?? data['avatar_url'] ?? data['image_url'],
        bio: data['bio'],
      );
    } catch (e) {
      return null;
    }
  }

  /// Sync user with backend - calls /api/users/sync with Clerk token
  Future<Map<String, dynamic>?> _syncUserWithBackend() async {
    try {
      final sessionToken = await getSessionToken();
      if (sessionToken == null) return null;

      _backendApi.options.headers['Authorization'] = 'Bearer $sessionToken';

      final response = await _backendApi.post('/api/users/sync');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final backendUser = response.data as Map<String, dynamic>;
        // Update stored user data with backend response
        await storage.write(key: _userDataKey, value: jsonEncode(backendUser));
        return backendUser;
      }
      return null;
    } catch (e) {
      // Silently fail - user can still use the app
      print('Failed to sync user with backend: $e');
      return null;
    }
  }

  /// Check username availability
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    try {
      final response = await _backendApi.get(
        '/api/users/check-username',
        queryParameters: {'username': username},
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Fallback to local check
      final takenUsernames = ['admin', 'test', 'user', 'demo', 'toolkudu'];
      final isAvailable = !takenUsernames.contains(username.toLowerCase());
      return {'available': isAvailable};
    }
  }

  /// Generate username from email
  String generateUsernameFromEmail(String email) {
    var username = email.split('@').first.toLowerCase();
    username = username.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (username.length < 3) username = '${username}user';
    return username;
  }

  /// Handle Dio errors
  Map<String, dynamic> _handleDioError(DioException e, String defaultMessage) {
    if (e.response?.data is Map) {
      final errors = e.response?.data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return {
          'success': false,
          'error': errors.first['message'] ??
              errors.first['long_message'] ??
              defaultMessage,
        };
      }
    }
    return {'success': false, 'error': defaultMessage};
  }
}
