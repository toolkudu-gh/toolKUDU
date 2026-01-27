import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import {
  query,
  queryOne,
  queryReturning,
  authenticate,
  success,
  created,
  noContent,
  badRequest,
  notFound,
  forbidden,
  conflict,
  serverError,
  parseBody,
  getPathParam,
  isValidUUID,
} from '@toolkudu/shared';
import {
  ToolboxPermission,
  ToolboxPermissionResponse,
  AddPermissionInput,
  PermissionLevel,
} from '../models/sharing';

// Get current user's ID from Cognito sub
async function getCurrentUserId(cognitoSub: string): Promise<string | null> {
  const user = await queryOne<{ id: string }>(
    'SELECT id FROM users WHERE cognito_sub = $1',
    [cognitoSub]
  );
  return user?.id || null;
}

// Check if user owns toolbox
async function checkToolboxOwnership(
  toolboxId: string,
  userId: string
): Promise<boolean> {
  const result = await queryOne(
    'SELECT 1 FROM toolboxes WHERE id = $1 AND user_id = $2',
    [toolboxId, userId]
  );
  return !!result;
}

// Get permissions for a toolbox
export async function getPermissions(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolboxId = getPathParam(event, 'id');

    if (!toolboxId || !isValidUUID(toolboxId)) {
      return badRequest('Invalid toolbox ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const isOwner = await checkToolboxOwnership(toolboxId, currentUserId);
    if (!isOwner) {
      return forbidden('You do not own this toolbox');
    }

    const result = await query<
      ToolboxPermission & {
        username: string;
        display_name: string | null;
        avatar_url: string | null;
      }
    >(
      `SELECT tp.*, u.username, u.display_name, u.avatar_url
       FROM toolbox_permissions tp
       INNER JOIN users u ON u.id = tp.user_id
       WHERE tp.toolbox_id = $1
       ORDER BY u.username`,
      [toolboxId]
    );

    const permissions: ToolboxPermissionResponse[] = result.rows.map((p) => ({
      id: p.id,
      userId: p.user_id,
      username: p.username,
      displayName: p.display_name,
      avatarUrl: p.avatar_url,
      permissionLevel: p.permission_level,
      createdAt: p.created_at,
    }));

    return success(permissions);
  } catch (error) {
    console.error('Error getting permissions:', error);
    return serverError('Failed to get permissions');
  }
}

// Add permission for a user
export async function addPermission(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolboxId = getPathParam(event, 'id');
    const body = parseBody<AddPermissionInput>(event);

    if (!toolboxId || !isValidUUID(toolboxId)) {
      return badRequest('Invalid toolbox ID');
    }

    if (!body || !body.userId || !isValidUUID(body.userId)) {
      return badRequest('Valid user ID is required');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const isOwner = await checkToolboxOwnership(toolboxId, currentUserId);
    if (!isOwner) {
      return forbidden('You do not own this toolbox');
    }

    const { userId, permissionLevel } = body;

    // Cannot add permission for self
    if (userId === currentUserId) {
      return badRequest('Cannot add permission for yourself');
    }

    // Check if target user exists
    const targetUser = await queryOne<{
      id: string;
      username: string;
      display_name: string | null;
      avatar_url: string | null;
    }>('SELECT id, username, display_name, avatar_url FROM users WHERE id = $1', [userId]);
    if (!targetUser) {
      return notFound('Target user not found');
    }

    // Check if permission already exists
    const existing = await queryOne(
      'SELECT 1 FROM toolbox_permissions WHERE toolbox_id = $1 AND user_id = $2',
      [toolboxId, userId]
    );
    if (existing) {
      return conflict('Permission already exists for this user');
    }

    // Validate permission level
    const validLevels: PermissionLevel[] = ['view', 'borrow'];
    const level = permissionLevel && validLevels.includes(permissionLevel)
      ? permissionLevel
      : 'view';

    const permission = await queryReturning<ToolboxPermission>(
      `INSERT INTO toolbox_permissions (toolbox_id, user_id, permission_level)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [toolboxId, userId, level]
    );

    if (!permission) {
      return serverError('Failed to add permission');
    }

    const response: ToolboxPermissionResponse = {
      id: permission.id,
      userId: permission.user_id,
      username: targetUser.username,
      displayName: targetUser.display_name,
      avatarUrl: targetUser.avatar_url,
      permissionLevel: permission.permission_level,
      createdAt: permission.created_at,
    };

    return created(response);
  } catch (error) {
    console.error('Error adding permission:', error);
    return serverError('Failed to add permission');
  }
}

// Update permissions (bulk update)
export async function updatePermissions(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolboxId = getPathParam(event, 'id');
    const body = parseBody<{ permissions: Array<{ userId: string; permissionLevel: PermissionLevel }> }>(event);

    if (!toolboxId || !isValidUUID(toolboxId)) {
      return badRequest('Invalid toolbox ID');
    }

    if (!body || !Array.isArray(body.permissions)) {
      return badRequest('Permissions array is required');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const isOwner = await checkToolboxOwnership(toolboxId, currentUserId);
    if (!isOwner) {
      return forbidden('You do not own this toolbox');
    }

    const validLevels: PermissionLevel[] = ['view', 'borrow'];

    for (const { userId, permissionLevel } of body.permissions) {
      if (!userId || !isValidUUID(userId)) continue;
      if (!validLevels.includes(permissionLevel)) continue;

      await query(
        `UPDATE toolbox_permissions
         SET permission_level = $1
         WHERE toolbox_id = $2 AND user_id = $3`,
        [permissionLevel, toolboxId, userId]
      );
    }

    return success({ message: 'Permissions updated' });
  } catch (error) {
    console.error('Error updating permissions:', error);
    return serverError('Failed to update permissions');
  }
}

// Remove permission for a user
export async function removePermission(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolboxId = getPathParam(event, 'id');
    const userId = getPathParam(event, 'userId');

    if (!toolboxId || !isValidUUID(toolboxId)) {
      return badRequest('Invalid toolbox ID');
    }

    if (!userId || !isValidUUID(userId)) {
      return badRequest('Invalid user ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const isOwner = await checkToolboxOwnership(toolboxId, currentUserId);
    if (!isOwner) {
      return forbidden('You do not own this toolbox');
    }

    const result = await query(
      'DELETE FROM toolbox_permissions WHERE toolbox_id = $1 AND user_id = $2',
      [toolboxId, userId]
    );

    if (result.rowCount === 0) {
      return notFound('Permission not found');
    }

    return noContent();
  } catch (error) {
    console.error('Error removing permission:', error);
    return serverError('Failed to remove permission');
  }
}
