import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../models/user.dart';

/// Clerk Authentication Service
/// Handles authentication via Clerk's Frontend API
class ClerkAuthService {
  final FlutterSecureStorage storage;
  final Dio _clerkApi;
  final Dio _backendApi;

  static const String _sessionTokenKey = 'clerk_session_token';
  static const String _userDataKey = 'clerk_user_data';
  static const String _pendingEmailKey = 'clerk_pending_email';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: AppConfig.googleClientId,
    scopes: ['email', 'profile'],
  );

  // Clerk Frontend API base URL (extracted from publishable key)
  String get _clerkFrontendApi {
    // pk_test_Y2VydGFpbi1ha2l0YS02NC5jbGVyay5hY2NvdW50cy5kZXYk
    // Decode: certain-akita-64.clerk.accounts.dev
    try {
      final keyPart = AppConfig.clerkPublishableKey.replaceFirst('pk_test_', '').replaceFirst('pk_live_', '');
      final decoded = utf8.decode(base64.decode(keyPart));
      return 'https://$decoded';
    } catch (e) {
      return 'https://certain-akita-64.clerk.accounts.dev';
    }
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
          final sessionToken = data['created_session_id'] ?? data['session_token'];
          if (sessionToken != null) {
            await _saveSession(
              sessionToken: sessionToken,
              userData: data['user'] ?? {},
            );
            await _syncUserWithBackend(data['user']);
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
          final sessionToken = data['created_session_id'] ?? data['session_token'];
          final userData = data['user'] ?? {'email': email};

          await _saveSession(
            sessionToken: sessionToken ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
            userData: userData,
          );

          await _syncUserWithBackend(userData);

          return {
            'success': true,
            'accessToken': sessionToken,
            'user': userData,
          };
        }

        // Check if verification is needed
        if (data['status'] == 'needs_first_factor' || data['status'] == 'needs_second_factor') {
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

  /// Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign-in cancelled'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Use Google token directly and sync with backend (skip Clerk frontend API)
      final userData = {
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'avatarUrl': googleUser.photoUrl,
        'provider': 'google',
      };

      final sessionToken = 'google_${googleAuth.accessToken ?? DateTime.now().millisecondsSinceEpoch}';
      await _saveSession(sessionToken: sessionToken, userData: userData);

      // Sync with backend - this creates/updates user in our database
      final syncResult = await _syncUserWithBackend(userData);

      return {
        'success': true,
        'accessToken': sessionToken,
        'user': syncResult ?? userData,
        'isNewUser': syncResult?['isNewUser'] ?? true,
      };
    } catch (e) {
      return {'success': false, 'error': 'Google sign-in failed: $e'};
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
          final sessionToken = data['created_session_id'] ?? 'magic_${DateTime.now().millisecondsSinceEpoch}';
          final userData = data['user'] ?? {'email': email};

          await _saveSession(sessionToken: sessionToken, userData: userData);
          await _syncUserWithBackend(userData);
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
      await _googleSignIn.signOut();
    } catch (_) {}

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

  /// Get current user - fetches from backend if session token available
  Future<User?> getCurrentUser() async {
    try {
      final sessionToken = await getSessionToken();

      // Try to fetch from backend if we have a session token
      if (sessionToken != null && sessionToken.startsWith('session_')) {
        try {
          _backendApi.options.headers['Authorization'] = 'Bearer $sessionToken';
          final response = await _backendApi.get('/api/users/me/session');

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
      }

      // Fallback to stored local data
      final userData = await storage.read(key: _userDataKey);
      if (userData == null) return null;

      final data = jsonDecode(userData) as Map<String, dynamic>;

      return User(
        id: data['id']?.toString() ?? data['clerk_id']?.toString() ?? 'user_${data['email']?.hashCode}',
        username: data['username'] ?? data['email']?.toString().split('@').first ?? 'user',
        email: data['email']?.toString() ?? '',
        displayName: data['displayName'] ?? data['first_name'] ?? data['display_name'],
        avatarUrl: data['avatarUrl'] ?? data['avatar_url'] ?? data['image_url'],
        bio: data['bio'],
      );
    } catch (e) {
      return null;
    }
  }

  /// Sync user with backend - returns user data from backend
  Future<Map<String, dynamic>?> _syncUserWithBackend(Map<String, dynamic> userData) async {
    try {
      final email = userData['email'] ?? userData['email_addresses']?[0]?['email_address'];

      // Call the google-auth endpoint (no Clerk auth required)
      final response = await _backendApi.post('/api/users/google-auth', data: {
        'email': email,
        'displayName': userData['displayName'] ?? userData['first_name'],
        'avatarUrl': userData['avatarUrl'] ?? userData['image_url'],
        'googleId': userData['googleId'] ?? email?.hashCode.toString(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final backendUser = response.data as Map<String, dynamic>;

        // Update session token if provided
        if (backendUser['sessionToken'] != null) {
          await storage.write(key: _sessionTokenKey, value: backendUser['sessionToken']);
        }

        // Update stored user data with backend response
        await storage.write(key: _userDataKey, value: jsonEncode(backendUser));
        return backendUser;
      }
      return null;
    } catch (e) {
      // Silently fail - user can still use the app with local data
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
          'error': errors.first['message'] ?? errors.first['long_message'] ?? defaultMessage,
        };
      }
    }
    return {'success': false, 'error': defaultMessage};
  }
}
