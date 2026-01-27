import jwt, { JwtPayload } from 'jsonwebtoken';
import jwksClient, { SigningKey } from 'jwks-rsa';
import { APIGatewayProxyEvent } from 'aws-lambda';

export interface CognitoConfig {
  userPoolId: string;
  region: string;
  clientId: string;
}

export interface CognitoUser {
  sub: string;
  email: string;
  username: string;
  emailVerified: boolean;
  groups?: string[];
}

export interface AuthenticatedEvent extends APIGatewayProxyEvent {
  user: CognitoUser;
}

let client: jwksClient.JwksClient | null = null;

function getJwksClient(config: CognitoConfig): jwksClient.JwksClient {
  if (!client) {
    const jwksUri = `https://cognito-idp.${config.region}.amazonaws.com/${config.userPoolId}/.well-known/jwks.json`;
    client = jwksClient({
      jwksUri,
      cache: true,
      cacheMaxAge: 600000, // 10 minutes
      rateLimit: true,
      jwksRequestsPerMinute: 10,
    });
  }
  return client;
}

function getSigningKey(
  client: jwksClient.JwksClient,
  kid: string
): Promise<string> {
  return new Promise((resolve, reject) => {
    client.getSigningKey(kid, (err: Error | null, key?: SigningKey) => {
      if (err) {
        reject(err);
        return;
      }
      if (!key) {
        reject(new Error('No signing key found'));
        return;
      }
      const signingKey = key.getPublicKey();
      resolve(signingKey);
    });
  });
}

export async function verifyToken(
  token: string,
  config?: CognitoConfig
): Promise<CognitoUser> {
  const cognitoConfig: CognitoConfig = config || {
    userPoolId: process.env.COGNITO_USER_POOL_ID || '',
    region: process.env.AWS_REGION || 'us-east-1',
    clientId: process.env.COGNITO_CLIENT_ID || '',
  };

  if (!cognitoConfig.userPoolId) {
    throw new Error('COGNITO_USER_POOL_ID not configured');
  }

  // Decode without verification to get the kid
  const decoded = jwt.decode(token, { complete: true });
  if (!decoded || typeof decoded === 'string') {
    throw new Error('Invalid token format');
  }

  const kid = decoded.header.kid;
  if (!kid) {
    throw new Error('Token missing kid');
  }

  // Get the signing key
  const jwks = getJwksClient(cognitoConfig);
  const signingKey = await getSigningKey(jwks, kid);

  // Verify the token
  const issuer = `https://cognito-idp.${cognitoConfig.region}.amazonaws.com/${cognitoConfig.userPoolId}`;

  const payload = jwt.verify(token, signingKey, {
    issuer,
    algorithms: ['RS256'],
  }) as JwtPayload;

  // Validate token use (access or id token)
  if (payload.token_use !== 'access' && payload.token_use !== 'id') {
    throw new Error('Invalid token_use');
  }

  // Extract user info
  const user: CognitoUser = {
    sub: payload.sub || '',
    email: payload.email || '',
    username: payload['cognito:username'] || payload.username || '',
    emailVerified: payload.email_verified === true,
    groups: payload['cognito:groups'] || [],
  };

  return user;
}

export function extractToken(event: APIGatewayProxyEvent): string | null {
  const authHeader = event.headers?.Authorization || event.headers?.authorization;

  if (!authHeader) {
    return null;
  }

  if (authHeader.startsWith('Bearer ')) {
    return authHeader.slice(7);
  }

  return authHeader;
}

export async function authenticate(
  event: APIGatewayProxyEvent
): Promise<CognitoUser> {
  const token = extractToken(event);

  if (!token) {
    throw new Error('No authorization token provided');
  }

  return verifyToken(token);
}

// Middleware wrapper for Lambda handlers
export function withAuth<T extends APIGatewayProxyEvent>(
  handler: (event: AuthenticatedEvent) => Promise<unknown>
): (event: T) => Promise<{ statusCode: number; body: string; headers: Record<string, string> }> {
  return async (event: T) => {
    try {
      const user = await authenticate(event);
      const authenticatedEvent = { ...event, user } as AuthenticatedEvent;
      const result = await handler(authenticatedEvent);

      return {
        statusCode: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify(result),
      };
    } catch (error) {
      console.error('Authentication error:', error);

      const message = error instanceof Error ? error.message : 'Authentication failed';
      const isAuthError =
        message.includes('token') ||
        message.includes('authorization') ||
        message.includes('Authentication');

      return {
        statusCode: isAuthError ? 401 : 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({
          error: isAuthError ? 'Unauthorized' : 'Internal server error',
          message: process.env.NODE_ENV === 'development' ? message : undefined,
        }),
      };
    }
  };
}
