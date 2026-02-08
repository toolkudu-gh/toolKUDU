import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

// Secure storage instance
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthService(storage: storage);
});

// Auth state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? accessToken;
  final String? error;
  final bool requiresEmailVerification;
  final String? pendingVerificationEmail;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.accessToken,
    this.error,
    this.requiresEmailVerification = false,
    this.pendingVerificationEmail,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? accessToken,
    String? error,
    bool? requiresEmailVerification,
    String? pendingVerificationEmail,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      error: error,
      requiresEmailVerification: requiresEmailVerification ?? this.requiresEmailVerification,
      pendingVerificationEmail: pendingVerificationEmail ?? this.pendingVerificationEmail,
    );
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final isAuthenticated = await _authService.isAuthenticated();
      if (isAuthenticated) {
        final tokens = await _authService.getTokens();
        final user = await _authService.getCurrentUser();
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          accessToken: tokens?['accessToken'],
        );
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      requiresEmailVerification: false,
      pendingVerificationEmail: null,
    );

    try {
      final result = await _authService.signIn(email, password);
      if (result['success'] == true) {
        final user = await _authService.getCurrentUser();
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          accessToken: result['accessToken'],
        );
        return true;
      } else {
        // Check if user needs to verify email
        if (result['requiresConfirmation'] == true) {
          state = AuthState(
            isLoading: false,
            requiresEmailVerification: true,
            pendingVerificationEmail: email,
            error: 'Please verify your email to continue.',
          );
          return false;
        }

        state = AuthState(
          isLoading: false,
          error: result['error'] ?? 'Sign in failed',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );
      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = AuthState(
          isLoading: false,
          error: result['error'] ?? 'Sign up failed',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> confirmSignUp(String email, String code) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.confirmSignUp(email, code);
      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = AuthState(
          isLoading: false,
          error: result['error'] ?? 'Verification failed',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resendVerificationCode(String email) async {
    try {
      final result = await _authService.resendConfirmationCode(email);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = const AuthState();
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithGoogle();
      if (result['success'] == true) {
        final user = await _authService.getCurrentUser();
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          accessToken: result['accessToken'],
        );
        return true;
      } else {
        state = AuthState(
          isLoading: false,
          error: result['error'] ?? 'Google sign-in failed',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Request Magic Link
  Future<bool> requestMagicLink(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.requestMagicLink(email);
      state = state.copyWith(isLoading: false);

      if (result['success'] == true) {
        return true;
      } else {
        state = AuthState(
          isLoading: false,
          error: result['error'] ?? 'Failed to send magic link',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Verify Magic Link Code
  Future<bool> verifyMagicLinkCode(String code) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.verifyMagicLinkCode(code);
      if (result['success'] == true) {
        final user = await _authService.getCurrentUser();
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          accessToken: result['accessToken'],
        );
        return true;
      } else {
        state = AuthState(
          isLoading: false,
          error: result['error'] ?? 'Invalid code',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Handle OAuth Callback (from Clerk redirect)
  Future<bool> handleOAuthCallback({
    String? sessionToken,
    String? sessionId,
    String? handshakeToken,
    String? code,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.handleOAuthCallback(
        sessionToken: sessionToken,
        sessionId: sessionId,
        handshakeToken: handshakeToken,
        code: code,
      );

      if (result['success'] == true) {
        final user = await _authService.getCurrentUser();
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          accessToken: result['accessToken'],
        );
        return true;
      } else {
        state = AuthState(
          isLoading: false,
          error: result['error'] ?? 'OAuth authentication failed',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

final accessTokenProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).accessToken;
});
