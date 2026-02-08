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

          await _saveSession(
            sessionToken: sessionToken ??
                'session_${DateTime.now().millisecondsSinceEpoch}',
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

  /// Sign in with Google - redirects to Clerk's hosted sign-in page
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final redirectUrl = Uri.encodeComponent('$_webBaseUrl/auth/callback');

      // Use Clerk's hosted sign-in page with Google OAuth
      // Format: https://<clerk-domain>/sign-in#/?redirect_url=<url>
      final clerkSignInUrl = '$_clerkFrontendApi/sign-in'
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
  }) async {
    try {
      String? jwt;
      Map<String, dynamic> userData = {};

      // If we have a session token that looks like a JWT (starts with ey), use it directly
      if (sessionToken != null && sessionToken.startsWith('ey')) {
        jwt = sessionToken;
      }
      // If we have a session ID, get the JWT from Clerk
      else if (sessionId != null && sessionId.isNotEmpty) {
        // Get JWT token from Clerk's session token endpoint
        try {
          final tokenResponse = await _clerkApi.post(
            '$_clerkFrontendApi/v1/sessions/$sessionId/tokens',
          );

          if (tokenResponse.statusCode == 200) {
            jwt = tokenResponse.data['jwt'] as String?;
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
      // Try using the session token as-is (might work for some Clerk configurations)
      else if (sessionToken != null && sessionToken.isNotEmpty) {
        jwt = sessionToken;
      }

      if (jwt == null || jwt.isEmpty) {
        return {
          'success': false,
          'error': 'Could not obtain authentication token from Clerk',
        };
      }

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
      return _handleDioError(e, 'OAuth callback failed');
    } catch (e) {
      return {'success': false, 'error': 'OAuth callback failed: $e'};
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
          final sessionToken = data['created_session_id'] ??
              'magic_${DateTime.now().millisecondsSinceEpoch}';
          final userData = data['user'] ?? {'email': email};

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
