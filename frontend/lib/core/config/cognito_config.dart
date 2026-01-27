/// AWS Cognito Configuration
/// Replace these values with your actual AWS Cognito settings after deployment
class CognitoConfig {
  // Cognito User Pool ID (from AWS Console or serverless deployment output)
  // Format: region_poolId (e.g., us-east-1_abc123XYZ)
  static const String userPoolId = String.fromEnvironment(
    'COGNITO_USER_POOL_ID',
    defaultValue: 'YOUR_USER_POOL_ID',
  );

  // Cognito App Client ID (from AWS Console)
  static const String clientId = String.fromEnvironment(
    'COGNITO_CLIENT_ID',
    defaultValue: 'YOUR_CLIENT_ID',
  );

  // AWS Region
  static const String region = String.fromEnvironment(
    'AWS_REGION',
    defaultValue: 'us-east-1',
  );

  // Cognito Identity Pool ID (for federated identities - Google, etc.)
  static const String identityPoolId = String.fromEnvironment(
    'COGNITO_IDENTITY_POOL_ID',
    defaultValue: 'YOUR_IDENTITY_POOL_ID',
  );

  // Google OAuth Client ID (for Google Sign-In)
  // Get this from Google Cloud Console
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '492727045513-ppmj753k9nerb15i4tcnu8ipgvvhjnr1.apps.googleusercontent.com',
  );

  // API Gateway Base URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.toolkudu.com',
  );

  // Check if we're in development mode (mock auth)
  static bool get isDevelopment => userPoolId == 'YOUR_USER_POOL_ID';
}
