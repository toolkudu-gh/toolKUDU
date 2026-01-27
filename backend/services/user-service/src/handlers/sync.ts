import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import {
  queryOne,
  queryReturning,
  authenticate,
  created,
  success,
  badRequest,
  conflict,
  serverError,
  parseBody,
  validateRequired,
  formatValidationErrors,
  isValidEmail,
} from '@toolkudu/shared';
import { User, CreateUserInput } from '../models/user';

interface SyncUserInput {
  username: string;
  email?: string;
  displayName?: string;
}

// Sync user from Cognito to database (called after registration)
export async function syncUser(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const body = parseBody<SyncUserInput>(event);

    if (!body) {
      return badRequest('Invalid request body');
    }

    const errors = validateRequired(body, ['username']);
    if (errors.length > 0) {
      return badRequest(formatValidationErrors(errors));
    }

    const { username, displayName } = body;
    const email = body.email || cognitoUser.email;

    if (!email || !isValidEmail(email)) {
      return badRequest('Valid email is required');
    }

    // Validate username format
    if (!/^[a-zA-Z0-9_]{3,30}$/.test(username)) {
      return badRequest('Username must be 3-30 characters and contain only letters, numbers, and underscores');
    }

    // Check if user already exists by Cognito sub
    const existingUser = await queryOne<User>(
      'SELECT * FROM users WHERE cognito_sub = $1',
      [cognitoUser.sub]
    );

    if (existingUser) {
      // User already synced, return existing profile
      return success({
        id: existingUser.id,
        username: existingUser.username,
        displayName: existingUser.display_name,
        avatarUrl: existingUser.avatar_url,
        bio: existingUser.bio,
        followersCount: 0,
        followingCount: 0,
      });
    }

    // Check if username is taken
    const usernameTaken = await queryOne(
      'SELECT 1 FROM users WHERE username = $1',
      [username.toLowerCase()]
    );

    if (usernameTaken) {
      return conflict('Username is already taken');
    }

    // Check if email is taken (by another Cognito user)
    const emailTaken = await queryOne(
      'SELECT 1 FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (emailTaken) {
      return conflict('Email is already registered');
    }

    // Create user
    const newUser = await queryReturning<User>(
      `INSERT INTO users (cognito_sub, username, email, display_name)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [cognitoUser.sub, username.toLowerCase(), email.toLowerCase(), displayName || username]
    );

    if (!newUser) {
      return serverError('Failed to create user');
    }

    return created({
      id: newUser.id,
      username: newUser.username,
      displayName: newUser.display_name,
      avatarUrl: newUser.avatar_url,
      bio: newUser.bio,
      followersCount: 0,
      followingCount: 0,
    });
  } catch (error) {
    console.error('Error syncing user:', error);
    return serverError('Failed to sync user');
  }
}
