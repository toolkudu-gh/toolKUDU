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
  serverError,
  paginated,
  parseBody,
  getPathParam,
  getQueryParamInt,
  isValidUUID,
  validateRequired,
  formatValidationErrors,
} from '@toolkudu/shared';
import {
  Toolbox,
  ToolboxResponse,
  CreateToolboxInput,
  UpdateToolboxInput,
  VisibilityType,
} from '../models/tool';

// Get current user's ID from Cognito sub
async function getCurrentUserId(cognitoSub: string): Promise<string | null> {
  const user = await queryOne<{ id: string }>(
    'SELECT id FROM users WHERE cognito_sub = $1',
    [cognitoSub]
  );
  return user?.id || null;
}

// Convert DB toolbox to response format
function toToolboxResponse(
  toolbox: Toolbox & { tool_count?: string }
): ToolboxResponse {
  return {
    id: toolbox.id,
    userId: toolbox.user_id,
    name: toolbox.name,
    description: toolbox.description,
    visibility: toolbox.visibility,
    icon: toolbox.icon,
    color: toolbox.color,
    toolCount: parseInt(toolbox.tool_count || '0'),
    createdAt: toolbox.created_at,
    updatedAt: toolbox.updated_at,
  };
}

// Get all toolboxes for current user
export async function getToolboxes(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 20);

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    const offset = (page - 1) * pageSize;

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM toolboxes WHERE user_id = $1',
      [currentUserId]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<Toolbox & { tool_count: string }>(
      `SELECT tb.*,
        (SELECT COUNT(*) FROM tools WHERE toolbox_id = tb.id) as tool_count
       FROM toolboxes tb
       WHERE tb.user_id = $1
       ORDER BY tb.created_at DESC
       LIMIT $2 OFFSET $3`,
      [currentUserId, pageSize, offset]
    );

    const toolboxes = result.rows.map(toToolboxResponse);

    return paginated(toolboxes, total, page, pageSize);
  } catch (error) {
    console.error('Error getting toolboxes:', error);
    return serverError('Failed to get toolboxes');
  }
}

// Create a new toolbox
export async function createToolbox(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const body = parseBody<CreateToolboxInput>(event);

    if (!body) {
      return badRequest('Invalid request body');
    }

    const errors = validateRequired(body, ['name']);
    if (errors.length > 0) {
      return badRequest(formatValidationErrors(errors));
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    const { name, description, visibility, icon, color } = body;

    // Validate visibility
    const validVisibilities: VisibilityType[] = ['private', 'buddies', 'public'];
    const actualVisibility = visibility && validVisibilities.includes(visibility)
      ? visibility
      : 'private';

    const toolbox = await queryReturning<Toolbox>(
      `INSERT INTO toolboxes (user_id, name, description, visibility, icon, color)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [currentUserId, name, description || null, actualVisibility, icon || null, color || null]
    );

    if (!toolbox) {
      return serverError('Failed to create toolbox');
    }

    return created(toToolboxResponse({ ...toolbox, tool_count: '0' }));
  } catch (error) {
    console.error('Error creating toolbox:', error);
    return serverError('Failed to create toolbox');
  }
}

// Get a specific toolbox
export async function getToolbox(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const toolboxId = getPathParam(event, 'id');

    if (!toolboxId || !isValidUUID(toolboxId)) {
      return badRequest('Invalid toolbox ID');
    }

    let currentUserId: string | null = null;
    try {
      const cognitoUser = await authenticate(event);
      currentUserId = await getCurrentUserId(cognitoUser.sub);
    } catch {
      // User not authenticated
    }

    const toolbox = await queryOne<Toolbox & { tool_count: string }>(
      `SELECT tb.*,
        (SELECT COUNT(*) FROM tools WHERE toolbox_id = tb.id) as tool_count
       FROM toolboxes tb
       WHERE tb.id = $1`,
      [toolboxId]
    );

    if (!toolbox) {
      return notFound('Toolbox not found');
    }

    // Check access
    const hasAccess = await checkToolboxAccess(toolbox, currentUserId);
    if (!hasAccess) {
      return forbidden('You do not have access to this toolbox');
    }

    return success(toToolboxResponse(toolbox));
  } catch (error) {
    console.error('Error getting toolbox:', error);
    return serverError('Failed to get toolbox');
  }
}

// Update a toolbox
export async function updateToolbox(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolboxId = getPathParam(event, 'id');
    const body = parseBody<UpdateToolboxInput>(event);

    if (!toolboxId || !isValidUUID(toolboxId)) {
      return badRequest('Invalid toolbox ID');
    }

    if (!body) {
      return badRequest('Invalid request body');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Check ownership
    const existing = await queryOne<Toolbox>(
      'SELECT * FROM toolboxes WHERE id = $1',
      [toolboxId]
    );

    if (!existing) {
      return notFound('Toolbox not found');
    }

    if (existing.user_id !== currentUserId) {
      return forbidden('You do not own this toolbox');
    }

    const { name, description, visibility, icon, color } = body;

    // Build update query
    const updates: string[] = [];
    const values: unknown[] = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      values.push(name);
    }
    if (description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      values.push(description);
    }
    if (visibility !== undefined) {
      const validVisibilities: VisibilityType[] = ['private', 'buddies', 'public'];
      if (validVisibilities.includes(visibility)) {
        updates.push(`visibility = $${paramIndex++}`);
        values.push(visibility);
      }
    }
    if (icon !== undefined) {
      updates.push(`icon = $${paramIndex++}`);
      values.push(icon);
    }
    if (color !== undefined) {
      updates.push(`color = $${paramIndex++}`);
      values.push(color);
    }

    if (updates.length === 0) {
      return badRequest('No fields to update');
    }

    values.push(toolboxId);

    const result = await queryOne<Toolbox & { tool_count: string }>(
      `UPDATE toolboxes SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING *,
         (SELECT COUNT(*) FROM tools WHERE toolbox_id = toolboxes.id) as tool_count`,
      values
    );

    if (!result) {
      return serverError('Failed to update toolbox');
    }

    return success(toToolboxResponse(result));
  } catch (error) {
    console.error('Error updating toolbox:', error);
    return serverError('Failed to update toolbox');
  }
}

// Delete a toolbox
export async function deleteToolbox(
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
    const existing = await queryOne<Toolbox>(
      'SELECT * FROM toolboxes WHERE id = $1',
      [toolboxId]
    );

    if (!existing) {
      return notFound('Toolbox not found');
    }

    if (existing.user_id !== currentUserId) {
      return forbidden('You do not own this toolbox');
    }

    // Delete toolbox (tools and images cascade)
    await query('DELETE FROM toolboxes WHERE id = $1', [toolboxId]);

    return noContent();
  } catch (error) {
    console.error('Error deleting toolbox:', error);
    return serverError('Failed to delete toolbox');
  }
}

// Get toolboxes for a specific user (respects visibility)
export async function getUserToolboxes(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const userId = getPathParam(event, 'userId');
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 20);

    if (!userId || !isValidUUID(userId)) {
      return badRequest('Invalid user ID');
    }

    let currentUserId: string | null = null;
    let isBuddy = false;

    try {
      const cognitoUser = await authenticate(event);
      currentUserId = await getCurrentUserId(cognitoUser.sub);

      if (currentUserId && currentUserId !== userId) {
        const buddyCheck = await queryOne(
          'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
          [currentUserId, userId]
        );
        isBuddy = !!buddyCheck;
      }
    } catch {
      // User not authenticated
    }

    const offset = (page - 1) * pageSize;

    // Build visibility filter
    let visibilityFilter: string;
    const params: unknown[] = [userId];

    if (currentUserId === userId) {
      // Owner sees all their toolboxes
      visibilityFilter = '';
    } else if (isBuddy) {
      // Buddies see public and buddies-only
      visibilityFilter = "AND (tb.visibility = 'public' OR tb.visibility = 'buddies')";
    } else {
      // Others see only public
      visibilityFilter = "AND tb.visibility = 'public'";
    }

    // Also check for explicit permissions
    let permissionCheck = '';
    if (currentUserId && currentUserId !== userId) {
      permissionCheck = `
        OR tb.id IN (
          SELECT toolbox_id FROM toolbox_permissions WHERE user_id = $${params.length + 1}
        )`;
      params.push(currentUserId);
    }

    const countResult = await queryOne<{ count: string }>(
      `SELECT COUNT(*) as count FROM toolboxes tb
       WHERE tb.user_id = $1 ${visibilityFilter} ${permissionCheck}`,
      params
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<Toolbox & { tool_count: string }>(
      `SELECT tb.*,
        (SELECT COUNT(*) FROM tools WHERE toolbox_id = tb.id) as tool_count
       FROM toolboxes tb
       WHERE tb.user_id = $1 ${visibilityFilter} ${permissionCheck}
       ORDER BY tb.created_at DESC
       LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      [...params, pageSize, offset]
    );

    const toolboxes = result.rows.map(toToolboxResponse);

    return paginated(toolboxes, total, page, pageSize);
  } catch (error) {
    console.error('Error getting user toolboxes:', error);
    return serverError('Failed to get user toolboxes');
  }
}

// Helper: Check if user has access to a toolbox
async function checkToolboxAccess(
  toolbox: Toolbox,
  currentUserId: string | null
): Promise<boolean> {
  // Owner always has access
  if (currentUserId === toolbox.user_id) {
    return true;
  }

  // Public toolboxes are accessible to everyone
  if (toolbox.visibility === 'public') {
    return true;
  }

  // Not authenticated and not public
  if (!currentUserId) {
    return false;
  }

  // Check explicit permission
  const permission = await queryOne(
    'SELECT 1 FROM toolbox_permissions WHERE toolbox_id = $1 AND user_id = $2',
    [toolbox.id, currentUserId]
  );
  if (permission) {
    return true;
  }

  // Buddies-only: check buddy relationship
  if (toolbox.visibility === 'buddies') {
    const buddy = await queryOne(
      'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
      [currentUserId, toolbox.user_id]
    );
    return !!buddy;
  }

  return false;
}
