import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../models/user.dart';
import 'clerk_auth_service.dart';

/// Authentication Service
/// Uses Clerk for production, with mock auth fallback for development
class AuthService {
  final FlutterSecureStorage storage;
  late final ClerkAuthService _clerkAuth;

  // Storage keys for mock auth
  static const String _accessTokenKey = 'access_token';
  static const String _userKey = 'user_data';
  static const String _emailForMagicLinkKey = 'email_for_magic_link';
  static const String _pendingVerificationEmailsKey = 'pending_verification_emails';
  static const String _verifiedEmailsKey = 'verified_emails';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: AppConfig.googleClientId,
    scopes: ['email', 'profile'],
  );

  AuthService({required this.storage}) {
    _clerkAuth = ClerkAuthService(storage: storage);
  }

  /// Check if using mock auth (development mode)
  bool get _useMockAuth => AppConfig.enableMockAuth;

  Future<bool> isAuthenticated() async {
    if (_useMockAuth) {
      final token = await storage.read(key: _accessTokenKey);
      return token != null && token.isNotEmpty;
    }
    return await _clerkAuth.isAuthenticated();
  }

  Future<Map<String, String>?> getTokens() async {
    if (_useMockAuth) {
      final accessToken = await storage.read(key: _accessTokenKey);
      if (accessToken == null) return null;
      return {'accessToken': accessToken};
    }
    return await _clerkAuth.getTokens();
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? idToken,
  }) async {
    await storage.write(key: _accessTokenKey, value: accessToken);
  }

  Future<void> clearTokens() async {
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _userKey);
    await storage.delete(key: _emailForMagicLinkKey);
    if (!_useMockAuth) {
      await _clerkAuth.clearSession();
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    if (_useMockAuth) {
      return _mockSignIn(email, password);
    }
    return await _clerkAuth.signIn(email, password);
  }

  Future<Map<String, dynamic>> _mockSignIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (email.isEmpty) {
      return {'success': false, 'error': 'Email is required'};
    }

    if (password.length < 8) {
      return {'success': false, 'error': 'Password must be at least 8 characters'};
    }

    final normalizedEmail = email.toLowerCase();

    // Check if email is pending verification
    if (await _isEmailPendingVerification(normalizedEmail)) {
      return {
        'success': false,
        'error': 'Please verify your email before signing in.',
        'requiresConfirmation': true,
      };
    }

    // Check if email is verified or is a demo account
    final isVerified = await _isEmailVerified(normalizedEmail);
    final validTestEmails = ['test@example.com', 'demo@toolkudu.com'];
    final isDemoAccount = validTestEmails.contains(normalizedEmail);

    if (isDemoAccount) {
      if (password != 'Test1234') {
        return {'success': false, 'error': 'Invalid password. Demo password is Test1234'};
      }
    } else if (!isVerified) {
      return {'success': false, 'error': 'Account not found. Please sign up first.'};
    }

    const mockAccessToken = 'mock_access_token_verified';
    await storage.write(key: _userKey, value: normalizedEmail);
    await saveTokens(accessToken: mockAccessToken);

    return {'success': true, 'accessToken': mockAccessToken};
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    if (_useMockAuth) {
      return _mockSignUp(email: email, password: password, username: username);
    }
    return await _clerkAuth.signUp(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );
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

    await _addPendingVerificationEmail(email.toLowerCase());

    return {
      'success': true,
      'message': 'Account created! Please verify your email with code: 123456',
    };
  }

  Future<Map<String, dynamic>> confirmSignUp(String email, String code) async {
    if (_useMockAuth) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (code == '123456' || code.length == 6) {
        await _removePendingVerificationEmail(email);
        await _addVerifiedEmail(email);
        return {'success': true};
      }
      return {'success': false, 'error': 'Invalid verification code. Use 123456 for demo.'};
    }
    return await _clerkAuth.verifyEmail(code);
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    if (_useMockAuth) {
      return _mockGoogleSignIn();
    }
    return await _clerkAuth.signInWithGoogle();
  }

  Future<Map<String, dynamic>> _mockGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign-in was cancelled'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final isNewUser = !await _isEmailVerified(googleUser.email);
      if (isNewUser) {
        await _addVerifiedEmail(googleUser.email);
      }

      final autoUsername = await generateUniqueUsername(googleUser.email);

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
    } catch (e) {
      return {'success': false, 'error': 'Google sign-in failed: $e'};
    }
  }

  Future<Map<String, dynamic>> requestMagicLink(String email) async {
    if (_useMockAuth) {
      await Future.delayed(const Duration(milliseconds: 500));
      await storage.write(key: _emailForMagicLinkKey, value: email);
      return {
        'success': true,
        'message': 'Magic link sent! Check your email. (Demo mode: use code 123456)',
      };
    }
    return await _clerkAuth.requestMagicLink(email);
  }

  Future<Map<String, dynamic>> verifyMagicLinkCode(String code) async {
    if (_useMockAuth) {
      return _mockVerifyMagicLink(code);
    }
    return await _clerkAuth.verifyMagicLinkCode(code);
  }

  Future<Map<String, dynamic>> _mockVerifyMagicLink(String code) async {
    final email = await storage.read(key: _emailForMagicLinkKey);

    if (email == null) {
      return {
        'success': false,
        'error': 'No pending magic link request. Please request a new link.',
      };
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (code == '123456' || code.length == 6) {
      final isNewUser = !await _isEmailVerified(email);
      if (isNewUser) {
        await _removePendingVerificationEmail(email);
        await _addVerifiedEmail(email);
      }

      final autoUsername = await generateUniqueUsername(email);

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

    return {'success': false, 'error': 'Invalid code. Use 123456 for demo.'};
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    if (!_useMockAuth) {
      await _clerkAuth.signOut();
    }

    await clearTokens();
  }

  Future<User?> getCurrentUser() async {
    if (!_useMockAuth) {
      return await _clerkAuth.getCurrentUser();
    }

    try {
      final tokens = await getTokens();
      if (tokens == null) return null;

      final storedEmail = await storage.read(key: _userKey);
      final storedUsername = await storage.read(key: '${_userKey}_username');
      final email = storedEmail ?? 'test@example.com';
      final username = storedUsername ?? email.split('@').first;

      return User(
        id: 'mock-user-${email.hashCode}',
        username: username,
        email: email,
        displayName: username.isNotEmpty
            ? username[0].toUpperCase() + username.substring(1)
            : 'User',
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    final tokens = await getTokens();
    return tokens?['accessToken'];
  }

  Future<Map<String, dynamic>> resendConfirmationCode(String email) async {
    if (_useMockAuth) {
      return {'success': true, 'message': 'Code resent (demo mode)'};
    }
    return await _clerkAuth.resendVerificationCode(email);
  }

  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    if (_useMockAuth) {
      await Future.delayed(const Duration(milliseconds: 300));
      final takenUsernames = ['admin', 'test', 'user', 'demo', 'toolkudu'];
      final isAvailable = !takenUsernames.contains(username.toLowerCase());

      if (isAvailable) {
        return {'available': true};
      }

      return {
        'available': false,
        'suggestions': _generateUsernameSuggestions(username),
      };
    }
    return await _clerkAuth.checkUsernameAvailability(username);
  }

  List<String> _generateUsernameSuggestions(String username) {
    final normalizedUsername = username.toLowerCase();
    final currentYear = DateTime.now().year;

    return [
      '${normalizedUsername}_${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}',
      '${normalizedUsername}_tools',
      '${normalizedUsername}_$currentYear',
    ];
  }

  String generateUsernameFromEmail(String email) {
    var username = email.split('@').first.toLowerCase();
    username = username.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (username.length < 3) {
      username = '${username}user';
    }
    return username;
  }

  Future<String> generateUniqueUsername(String email) async {
    var baseUsername = generateUsernameFromEmail(email);
    final result = await checkUsernameAvailability(baseUsername);
    if (result['available'] == true) {
      return baseUsername;
    }
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return '${baseUsername}_$random';
  }

  // Helper methods for mock email verification tracking
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
}
