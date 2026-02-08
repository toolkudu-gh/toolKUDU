import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'clerk_auth_service.dart';

/// Authentication Service
/// Delegates all authentication to ClerkAuthService
class AuthService {
  final FlutterSecureStorage storage;
  late final ClerkAuthService _clerkAuth;

  AuthService({required this.storage}) {
    _clerkAuth = ClerkAuthService(storage: storage);
  }

  Future<bool> isAuthenticated() async {
    return await _clerkAuth.isAuthenticated();
  }

  Future<Map<String, String>?> getTokens() async {
    return await _clerkAuth.getTokens();
  }

  Future<void> clearTokens() async {
    await _clerkAuth.clearSession();
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    return await _clerkAuth.signIn(email, password);
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    return await _clerkAuth.signUp(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );
  }

  Future<Map<String, dynamic>> confirmSignUp(String email, String code) async {
    return await _clerkAuth.verifyEmail(code);
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    return await _clerkAuth.signInWithGoogle();
  }

  Future<Map<String, dynamic>> handleOAuthCallback({
    String? sessionToken,
    String? sessionId,
    String? handshakeToken,
    String? code,
  }) async {
    return await _clerkAuth.handleOAuthCallback(
      sessionToken: sessionToken,
      sessionId: sessionId,
      handshakeToken: handshakeToken,
      code: code,
    );
  }

  Future<Map<String, dynamic>> requestMagicLink(String email) async {
    return await _clerkAuth.requestMagicLink(email);
  }

  Future<Map<String, dynamic>> verifyMagicLinkCode(String code) async {
    return await _clerkAuth.verifyMagicLinkCode(code);
  }

  Future<void> signOut() async {
    await _clerkAuth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return await _clerkAuth.getCurrentUser();
  }

  Future<String?> getAccessToken() async {
    final tokens = await getTokens();
    return tokens?['accessToken'];
  }

  Future<Map<String, dynamic>> resendConfirmationCode(String email) async {
    return await _clerkAuth.resendVerificationCode(email);
  }

  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    return await _clerkAuth.checkUsernameAvailability(username);
  }

  String generateUsernameFromEmail(String email) {
    return _clerkAuth.generateUsernameFromEmail(email);
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
}
