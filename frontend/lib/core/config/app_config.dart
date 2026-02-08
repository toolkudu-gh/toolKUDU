/// App Configuration
/// Central configuration for ToolKUDU app
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://toolkudu-api-production.up.railway.app',
  );

  // Clerk Authentication (replacing Cognito)
  static const String clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_Y2VydGFpbi1ha2l0YS02NC5jbGVyay5hY2NvdW50cy5kZXYk',
  );

  // Google OAuth Client ID (for Google Sign-In)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '492727045513-ppmj753k9nerb15i4tcnu8ipgvvhjnr1.apps.googleusercontent.com',
  );

  // Environment checks
  static bool get isProduction => apiBaseUrl.contains('railway.app');
  static bool get isDevelopment => !isProduction;

  // Web base URL for OAuth redirects
  static String get webBaseUrl {
    if (isProduction) {
      return 'https://toolkudu-web-production.up.railway.app';
    }
    return 'http://localhost:3000';
  }
}
