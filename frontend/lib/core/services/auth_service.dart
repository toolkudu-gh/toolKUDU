import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/cognito_config.dart';
import '../models/user.dart';

class AuthService {
  final FlutterSecureStorage storage;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _idTokenKey = 'id_token';
  static const String _userKey = 'user_data';
  static const String _emailForMagicLinkKey = 'email_for_magic_link';
  static const String _pendingVerificationEmailsKey = 'pending_verification_emails';
  static const String _verifiedEmailsKey = 'verified_emails';

  late final CognitoUserPool _userPool;
  CognitoUser? _cognitoUser;
  CognitoUserSession? _session;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: CognitoConfig.googleClientId,
    scopes: ['email', 'profile'],
  );

  AuthService({required this.storage}) {
    _userPool = CognitoUserPool(
      CognitoConfig.userPoolId,
      CognitoConfig.clientId,
    );
  }

  Future<bool> isAuthenticated() async {
    if (CognitoConfig.isDevelopment) {
      final token = await storage.read(key: _accessTokenKey);
      return token != null && token.isNotEmpty;
    }

    try {
      if (_session != null && _session!.isValid()) {
        return true;
      }

      final token = await storage.read(key: _accessTokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, String>?> getTokens() async {
    final accessToken = await storage.read(key: _accessTokenKey);
    final refreshToken = await storage.read(key: _refreshTokenKey);
    final idToken = await storage.read(key: _idTokenKey);

    if (accessToken == null) return null;

    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken ?? '',
      'idToken': idToken ?? '',
    };
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
  }) async {
    await storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    if (idToken != null) {
      await storage.write(key: _idTokenKey, value: idToken);
    }
  }

  Future<void> clearTokens() async {
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
    await storage.delete(key: _idTokenKey);
    await storage.delete(key: _userKey);
    await storage.delete(key: _emailForMagicLinkKey);
    _session = null;
    _cognitoUser = null;
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    // Development mode - use mock auth
    if (CognitoConfig.isDevelopment) {
      return _mockSignIn(email, password);
    }

    try {
      _cognitoUser = CognitoUser(email, _userPool);

      final authDetails = AuthenticationDetails(
        username: email,
        password: password,
      );

      _session = await _cognitoUser!.authenticateUser(authDetails);

      if (_session != null && _session!.isValid()) {
        await saveTokens(
          accessToken: _session!.getAccessToken().getJwtToken()!,
          refreshToken: _session!.getRefreshToken()?.getToken(),
          idToken: _session!.getIdToken().getJwtToken(),
        );

        return {
          'success': true,
          'accessToken': _session!.getAccessToken().getJwtToken(),
        };
      }

      return {
        'success': false,
        'error': 'Authentication failed',
      };
    } on CognitoUserNewPasswordRequiredException {
      return {
        'success': false,
        'error': 'New password required. Please reset your password.',
        'requiresNewPassword': true,
      };
    } on CognitoUserMfaRequiredException {
      return {
        'success': false,
        'error': 'MFA code required',
        'requiresMfa': true,
      };
    } on CognitoUserCustomChallengeException {
      return {
        'success': false,
        'error': 'Custom challenge required',
      };
    } on CognitoUserConfirmationNecessaryException {
      return {
        'success': false,
        'error': 'User confirmation required. Please check your email.',
        'requiresConfirmation': true,
      };
    } on CognitoClientException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Authentication error',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Invalid email or password',
      };
    }
  }

  Future<Map<String, dynamic>> _mockSignIn(String email, String password) async {
    // In development mode, still validate credentials properly
    // This prevents the "wrong password" issue
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network

    if (email.isEmpty) {
      return {
        'success': false,
        'error': 'Email is required',
      };
    }

    if (password.length < 8) {
      return {
        'success': false,
        'error': 'Password must be at least 8 characters',
      };
    }

    final normalizedEmail = email.toLowerCase();

    // Check if email is pending verification (user signed up but not verified)
    if (await _isEmailPendingVerification(normalizedEmail)) {
      return {
        'success': false,
        'error': 'Please verify your email before signing in.',
        'requiresConfirmation': true,
      };
    }

    // Check if email is verified (user completed verification flow)
    final isVerified = await _isEmailVerified(normalizedEmail);

    // Allow verified users OR demo accounts
    final validTestEmails = ['test@example.com', 'demo@toolkudu.com'];
    const validTestPassword = 'Test1234';

    // Demo accounts don't need verification
    final isDemoAccount = validTestEmails.contains(normalizedEmail);

    if (isDemoAccount) {
      if (password != validTestPassword) {
        return {
          'success': false,
          'error': 'Invalid password. Demo password is Test1234',
        };
      }
    } else if (!isVerified) {
      // For non-demo accounts, check if they exist in verified list
      return {
        'success': false,
        'error': 'Account not found. Please sign up first.',
      };
    }

    // For verified non-demo accounts, accept any valid password
    // (In real app, this would check against stored credentials)
    if (!isDemoAccount && password.length < 8) {
      return {
        'success': false,
        'error': 'Invalid password',
      };
    }

    const mockAccessToken = 'mock_access_token_verified';
    const mockRefreshToken = 'mock_refresh_token';

    // Store the user email for getCurrentUser
    await storage.write(key: _userKey, value: normalizedEmail);

    await saveTokens(
      accessToken: mockAccessToken,
      refreshToken: mockRefreshToken,
    );

    return {
      'success': true,
      'accessToken': mockAccessToken,
    };
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    if (CognitoConfig.isDevelopment) {
      return _mockSignUp(email: email, password: password, username: username);
    }

    try {
      final userAttributes = [
        AttributeArg(name: 'email', value: email),
        AttributeArg(name: 'preferred_username', value: username),
        if (displayName != null) AttributeArg(name: 'name', value: displayName),
      ];

      await _userPool.signUp(
        email,
        password,
        userAttributes: userAttributes,
      );

      return {
        'success': true,
        'message': 'Please check your email for verification code',
      };
    } on CognitoClientException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Sign up failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> _mockSignUp({
    required String email,
    required String password,
    required String username,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email.isEmpty || !email.contains('@')) {
      return {'success': false, 'error': 'Invalid email address'};
    }
    if (password.length < 8) {
      return {'success': false, 'error': 'Password must be at least 8 characters'};
    }
    if (username.length < 3) {
      return {'success': false, 'error': 'Username must be at least 3 characters'};
    }

    // Store email as pending verification (development mode)
    await _addPendingVerificationEmail(email.toLowerCase());

    return {
      'success': true,
      'message': 'Account created! Please verify your email with code: 123456',
    };
  }

  // Helper methods for development mode email verification tracking
  Future<void> _addPendingVerificationEmail(String email) async {
    final pending = await _getPendingVerificationEmails();
    pending.add(email.toLowerCase());
    await storage.write(key: _pendingVerificationEmailsKey, value: pending.join(','));
  }

  Future<void> _removePendingVerificationEmail(String email) async {
    final pending = await _getPendingVerificationEmails();
    pending.remove(email.toLowerCase());
    await storage.write(key: _pendingVerificationEmailsKey, value: pending.join(','));
  }

  Future<Set<String>> _getPendingVerificationEmails() async {
    final data = await storage.read(key: _pendingVerificationEmailsKey);
    if (data == null || data.isEmpty) return {};
    return data.split(',').toSet();
  }

  Future<void> _addVerifiedEmail(String email) async {
    final verified = await _getVerifiedEmails();
    verified.add(email.toLowerCase());
    await storage.write(key: _verifiedEmailsKey, value: verified.join(','));
  }

  Future<Set<String>> _getVerifiedEmails() async {
    final data = await storage.read(key: _verifiedEmailsKey);
    if (data == null || data.isEmpty) return {};
    return data.split(',').toSet();
  }

  Future<bool> _isEmailVerified(String email) async {
    final verified = await _getVerifiedEmails();
    return verified.contains(email.toLowerCase());
  }

  Future<bool> _isEmailPendingVerification(String email) async {
    final pending = await _getPendingVerificationEmails();
    return pending.contains(email.toLowerCase());
  }

  Future<Map<String, dynamic>> confirmSignUp(String email, String code) async {
    if (CognitoConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));

      // In dev mode, accept code "123456" or any 6-digit code
      if (code == '123456' || code.length == 6) {
        // Mark email as verified
        await _removePendingVerificationEmail(email);
        await _addVerifiedEmail(email);
        return {'success': true};
      }
      return {'success': false, 'error': 'Invalid verification code. Use 123456 for demo.'};
    }

    try {
      _cognitoUser = CognitoUser(email, _userPool);
      final confirmed = await _cognitoUser!.confirmRegistration(code);

      return {
        'success': confirmed,
        'error': confirmed ? null : 'Confirmation failed',
      };
    } on CognitoClientException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Confirmation failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Google Sign-In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {
          'success': false,
          'error': 'Google sign-in was cancelled',
        };
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (CognitoConfig.isDevelopment) {
        // Mock Google sign-in for development
        // Auto-register Google user if not already registered
        final isNewUser = !await _isEmailVerified(googleUser.email);
        if (isNewUser) {
          await _addVerifiedEmail(googleUser.email);
        }

        // Auto-generate username from email for Google users
        final autoUsername = await generateUniqueUsername(googleUser.email);

        // Store the user email for getCurrentUser
        await storage.write(key: _userKey, value: googleUser.email);
        await storage.write(key: '${_userKey}_username', value: autoUsername);

        await saveTokens(
          accessToken: 'google_mock_token_${googleUser.email}',
          idToken: googleAuth.idToken,
        );

        return {
          'success': true,
          'accessToken': 'google_mock_token',
          'isNewUser': isNewUser,
          'user': {
            'email': googleUser.email,
            'displayName': googleUser.displayName,
            'photoUrl': googleUser.photoUrl,
            'username': autoUsername,
          },
        };
      }

      // For production: Exchange Google token with Cognito
      // This requires setting up Cognito Identity Pool with Google as an identity provider
      // The token would be exchanged for Cognito credentials

      return {
        'success': true,
        'accessToken': googleAuth.accessToken,
        'idToken': googleAuth.idToken,
        'user': {
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Google sign-in failed: ${e.toString()}',
      };
    }
  }

  // Magic Link - Request
  Future<Map<String, dynamic>> requestMagicLink(String email) async {
    if (CognitoConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));
      await storage.write(key: _emailForMagicLinkKey, value: email);
      return {
        'success': true,
        'message': 'Magic link sent! Check your email. (Demo mode: use code 123456)',
      };
    }

    try {
      // In Cognito, magic links are implemented via custom authentication flow
      // or using the forgotPassword flow with a custom lambda trigger
      _cognitoUser = CognitoUser(email, _userPool);

      // Initiate custom auth - this requires a custom Lambda trigger in Cognito
      // that sends an email with a verification code/link
      await _cognitoUser!.initiateAuth(AuthenticationDetails(
        username: email,
      ));

      await storage.write(key: _emailForMagicLinkKey, value: email);

      return {
        'success': true,
        'message': 'Magic link sent! Check your email.',
      };
    } catch (e) {
      // If custom auth is not set up, fall back to password reset flow
      try {
        _cognitoUser = CognitoUser(email, _userPool);
        await _cognitoUser!.forgotPassword();
        await storage.write(key: _emailForMagicLinkKey, value: email);

        return {
          'success': true,
          'message': 'A verification code has been sent to your email.',
        };
      } catch (e2) {
        return {
          'success': false,
          'error': 'Failed to send magic link: ${e2.toString()}',
        };
      }
    }
  }

  // Magic Link - Verify code
  Future<Map<String, dynamic>> verifyMagicLinkCode(String code) async {
    final email = await storage.read(key: _emailForMagicLinkKey);

    if (email == null) {
      return {
        'success': false,
        'error': 'No pending magic link request. Please request a new link.',
      };
    }

    if (CognitoConfig.isDevelopment) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (code == '123456' || code.length == 6) {
        // Auto-register user if not already registered
        final isNewUser = !await _isEmailVerified(email);
        if (isNewUser) {
          // Remove from pending if exists and add to verified
          await _removePendingVerificationEmail(email);
          await _addVerifiedEmail(email);
        }

        // Auto-generate username from email for Magic Link users
        final autoUsername = await generateUniqueUsername(email);

        // Store the current user's email and username for getCurrentUser
        await storage.write(key: _userKey, value: email);
        await storage.write(key: '${_userKey}_username', value: autoUsername);

        await saveTokens(
          accessToken: 'magic_link_mock_token_$email',
          refreshToken: 'magic_link_mock_refresh',
        );
        await storage.delete(key: _emailForMagicLinkKey);

        return {
          'success': true,
          'accessToken': 'magic_link_mock_token',
          'isNewUser': isNewUser,
          'username': autoUsername,
        };
      }

      return {
        'success': false,
        'error': 'Invalid code. Use 123456 for demo.',
      };
    }

    try {
      // This would typically complete the custom auth challenge
      // or verify the forgot password code
      _cognitoUser = CognitoUser(email, _userPool);

      // For custom auth flow:
      _session = await _cognitoUser!.sendCustomChallengeAnswer(code);

      if (_session != null && _session!.isValid()) {
        await saveTokens(
          accessToken: _session!.getAccessToken().getJwtToken()!,
          refreshToken: _session!.getRefreshToken()?.getToken(),
          idToken: _session!.getIdToken().getJwtToken(),
        );
        await storage.delete(key: _emailForMagicLinkKey);

        return {
          'success': true,
          'accessToken': _session!.getAccessToken().getJwtToken(),
        };
      }

      return {
        'success': false,
        'error': 'Invalid or expired code',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Verification failed: ${e.toString()}',
      };
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    if (_cognitoUser != null) {
      try {
        await _cognitoUser!.signOut();
      } catch (_) {}
    }

    await clearTokens();
  }

  Future<User?> getCurrentUser() async {
    try {
      final tokens = await getTokens();
      if (tokens == null) return null;

      if (CognitoConfig.isDevelopment) {
        // Get the stored user email (from magic link, regular login, or Google sign-in)
        final storedEmail = await storage.read(key: _userKey);
        final storedUsername = await storage.read(key: '${_userKey}_username');
        final email = storedEmail ?? 'test@example.com';
        // Use stored username if available, otherwise derive from email
        final username = storedUsername ?? email.split('@').first;

        return User(
          id: 'mock-user-${email.hashCode}',
          username: username,
          email: email,
          displayName: username.isNotEmpty
              ? username[0].toUpperCase() + username.substring(1)
              : 'User',
        );
      }

      if (_cognitoUser != null) {
        final attributes = await _cognitoUser!.getUserAttributes();
        if (attributes != null) {
          String? email, username, displayName, id;

          for (final attr in attributes) {
            switch (attr.name) {
              case 'sub':
                id = attr.value;
                break;
              case 'email':
                email = attr.value;
                break;
              case 'preferred_username':
                username = attr.value;
                break;
              case 'name':
                displayName = attr.value;
                break;
            }
          }

          return User(
            id: id ?? 'unknown',
            username: username ?? email?.split('@').first ?? 'user',
            email: email ?? '',
            displayName: displayName,
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: _accessTokenKey);
  }

  Future<Map<String, dynamic>> resendConfirmationCode(String email) async {
    if (CognitoConfig.isDevelopment) {
      return {'success': true, 'message': 'Code resent (demo mode)'};
    }

    try {
      _cognitoUser = CognitoUser(email, _userPool);
      await _cognitoUser!.resendConfirmationCode();
      return {'success': true, 'message': 'Confirmation code resent'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check if a username is available
  /// Returns { available: bool, suggestions: List<String>? }
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    // In development mode, mock the availability check
    // Treat certain usernames as "taken" for testing
    final takenUsernames = ['admin', 'test', 'user', 'demo', 'toolkudu'];
    final normalizedUsername = username.toLowerCase();
    final isAvailable = !takenUsernames.contains(normalizedUsername);

    if (isAvailable) {
      return {'available': true};
    }

    // Generate suggestions for taken usernames
    final suggestions = _generateUsernameSuggestions(username);
    return {
      'available': false,
      'suggestions': suggestions,
    };
  }

  /// Generate username suggestions when the requested username is taken
  List<String> _generateUsernameSuggestions(String username) {
    final normalizedUsername = username.toLowerCase();
    final currentYear = DateTime.now().year;

    // Mix of number and tool-themed suffixes
    final suggestions = <String>[
      '${normalizedUsername}_${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
      '${normalizedUsername}_tools',
      '${normalizedUsername}_$currentYear',
    ];

    return suggestions.take(3).toList();
  }

  /// Suggest available usernames based on email
  String generateUsernameFromEmail(String email) {
    // Extract prefix from email
    var username = email.split('@').first.toLowerCase();

    // Remove invalid characters (keep only alphanumeric and underscore)
    username = username.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    // Ensure minimum length
    if (username.length < 3) {
      username = '${username}user';
    }

    return username;
  }

  /// Generate a unique username for Google/Magic Link users
  Future<String> generateUniqueUsername(String email) async {
    var baseUsername = generateUsernameFromEmail(email);

    // Check if base username is available
    final result = await checkUsernameAvailability(baseUsername);
    if (result['available'] == true) {
      return baseUsername;
    }

    // If not available, append random number
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return '${baseUsername}_$random';
  }
}
