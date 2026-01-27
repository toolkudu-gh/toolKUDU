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
  Tool,
  ToolImage,
  ToolResponse,
  ToolImageResponse,
  CreateToolInput,
  UpdateToolInput,
  Toolbox,
} from '../models/tool';

const S3_BUCKET = process.env.S3_BUCKET || '';
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';

// Get current user's ID from Cognito sub
async function getCurrentUserId(cognitoSub: string): Promise<string | null> {
  const user = await queryOne<{ id: string }>(
    'SELECT id FROM users WHERE cognito_sub = $1',
    [cognitoSub]
  );
  return user?.id || null;
}

// Get image URL from S3 key
function getImageUrl(s3Key: string, bucket: string): string {
  return `https://${bucket}.s3.${AWS_REGION}.amazonaws.com/${s3Key}`;
}

// Convert DB tool to response format
async function toToolResponse(tool: Tool): Promise<ToolResponse> {
  // Get images
  const imagesResult = await query<ToolImage>(
    'SELECT * FROM tool_images WHERE tool_id = $1 ORDER BY order_index',
    [tool.id]
  );

  const images: ToolImageResponse[] = imagesResult.rows.map((img) => ({
    id: img.id,
    url: getImageUrl(img.s3_key, img.s3_bucket),
    orderIndex: img.order_index,
  }));

  // Check if tool has tracker
  const tracker = await queryOne(
    'SELECT 1 FROM tool_trackers WHERE tool_id = $1 AND is_active = true',
    [tool.id]
  );

  return {
    id: tool.id,
    toolboxId: tool.toolbox_id,
    name: tool.name,
    description: tool.description,
    category: tool.category,
    brand: tool.brand,
    model: tool.model,
    serialNumber: tool.serial_number,
    purchaseDate: tool.purchase_date,
    purchasePrice: tool.purchase_price,
    notes: tool.notes,
    isAvailable: tool.is_available,
    images,
    hasTracker: !!tracker,
    createdAt: tool.created_at,
    updatedAt: tool.updated_at,
  };
}

// Check if user owns toolbox
async function checkToolboxOwnership(
  toolboxId: string,
  userId: string
): Promise<Toolbox | null> {
  return queryOne<Toolbox>(
    'SELECT * FROM toolboxes WHERE id = $1 AND user_id = $2',
    [toolboxId, userId]
  );
}

// Check if user has access to toolbox
async function hasToolboxAccess(
  toolboxId: string,
  userId: string | null
): Promise<boolean> {
  const toolbox = await queryOne<Toolbox>(
    'SELECT * FROM toolboxes WHERE id = $1',
    [toolboxId]
  );

  if (!toolbox) return false;

  // Owner always has access
  if (userId === toolbox.user_id) return true;

  // Public toolbox
  if (toolbox.visibility === 'public') return true;

  if (!userId) return false;

  // Check explicit permission
  const permission = await queryOne(
    'SELECT 1 FROM toolbox_permissions WHERE toolbox_id = $1 AND user_id = $2',
    [toolboxId, userId]
  );
  if (permission) return true;

  // Buddies-only
  if (toolbox.visibility === 'buddies') {
    const buddy = await queryOne(
      'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
      [userId, toolbox.user_id]
    );
    return !!buddy;
  }

  return false;
}

// Get tools in a toolbox
export async function getTools(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const toolboxId = getPathParam(event, 'toolboxId');
    const page = getQueryParamInt(event, 'page', 1);
    const pageSize = getQueryParamInt(event, 'pageSize', 20);

    if (!toolboxId || !isValidUUID(toolboxId)) {
      return badRequest('Invalid toolbox ID');
    }

    let currentUserId: string | null = null;
    try {
      const cognitoUser = await authenticate(event);
      currentUserId = await getCurrentUserId(cognitoUser.sub);
    } catch {
      // Not authenticated
    }

    // Check access
    const hasAccess = await hasToolboxAccess(toolboxId, currentUserId);
    if (!hasAccess) {
      return forbidden('You do not have access to this toolbox');
    }

    const offset = (page - 1) * pageSize;

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM tools WHERE toolbox_id = $1',
      [toolboxId]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<Tool>(
      `SELECT * FROM tools
       WHERE toolbox_id = $1
       ORDER BY name
       LIMIT $2 OFFSET $3`,
      [toolboxId, pageSize, offset]
    );

    const tools = await Promise.all(result.rows.map(toToolResponse));

    return paginated(tools, total, page, pageSize);
  } catch (error) {
    console.error('Error getting tools:', error);
    return serverError('Failed to get tools');
  }
}

// Create a new tool
export async function createTool(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolboxId = getPathParam(event, 'toolboxId');
    const body = parseBody<CreateToolInput>(event);

    if (!toolboxId || !isValidUUID(toolboxId)) {
      return badRequest('Invalid toolbox ID');
    }

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

    // Check ownership
    const toolbox = await checkToolboxOwnership(toolboxId, currentUserId);
    if (!toolbox) {
      return forbidden('You do not own this toolbox');
    }

    const {
      name,
      description,
      category,
      brand,
      model,
      serialNumber,
      purchaseDate,
      purchasePrice,
      notes,
    } = body;

    const tool = await queryReturning<Tool>(
      `INSERT INTO tools (
        toolbox_id, name, description, category, brand, model,
        serial_number, purchase_date, purchase_price, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *`,
      [
        toolboxId,
        name,
        description || null,
        category || null,
        brand || null,
        model || null,
        serialNumber || null,
        purchaseDate || null,
        purchasePrice || null,
        notes || null,
      ]
    );

    if (!tool) {
      return serverError('Failed to create tool');
    }

    const response = await toToolResponse(tool);
    return created(response);
  } catch (error) {
    console.error('Error creating tool:', error);
    return serverError('Failed to create tool');
  }
}

// Get a specific tool
export async function getTool(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const toolId = getPathParam(event, 'id');

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    let currentUserId: string | null = null;
    try {
      const cognitoUser = await authenticate(event);
      currentUserId = await getCurrentUserId(cognitoUser.sub);
    } catch {
      // Not authenticated
    }

    const tool = await queryOne<Tool>(
      'SELECT * FROM tools WHERE id = $1',
      [toolId]
    );

    if (!tool) {
      return notFound('Tool not found');
    }

    // Check access via toolbox
    const hasAccess = await hasToolboxAccess(tool.toolbox_id, currentUserId);
    if (!hasAccess) {
      return forbidden('You do not have access to this tool');
    }

    const response = await toToolResponse(tool);
    return success(response);
  } catch (error) {
    console.error('Error getting tool:', error);
    return serverError('Failed to get tool');
  }
}

// Update a tool
export async function updateTool(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');
    const body = parseBody<UpdateToolInput>(event);

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    if (!body) {
      return badRequest('Invalid request body');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Get the tool and check ownership via toolbox
    const tool = await queryOne<Tool>(
      'SELECT * FROM tools WHERE id = $1',
      [toolId]
    );

    if (!tool) {
      return notFound('Tool not found');
    }

    const toolbox = await checkToolboxOwnership(tool.toolbox_id, currentUserId);
    if (!toolbox) {
      return forbidden('You do not own this tool');
    }

    const {
      name,
      description,
      category,
      brand,
      model,
      serialNumber,
      purchaseDate,
      purchasePrice,
      notes,
      toolboxId,
    } = body;

    // If moving to different toolbox, verify ownership
    if (toolboxId && toolboxId !== tool.toolbox_id) {
      const newToolbox = await checkToolboxOwnership(toolboxId, currentUserId);
      if (!newToolbox) {
        return forbidden('You do not own the target toolbox');
      }
    }

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
    if (category !== undefined) {
      updates.push(`category = $${paramIndex++}`);
      values.push(category);
    }
    if (brand !== undefined) {
      updates.push(`brand = $${paramIndex++}`);
      values.push(brand);
    }
    if (model !== undefined) {
      updates.push(`model = $${paramIndex++}`);
      values.push(model);
    }
    if (serialNumber !== undefined) {
      updates.push(`serial_number = $${paramIndex++}`);
      values.push(serialNumber);
    }
    if (purchaseDate !== undefined) {
      updates.push(`purchase_date = $${paramIndex++}`);
      values.push(purchaseDate);
    }
    if (purchasePrice !== undefined) {
      updates.push(`purchase_price = $${paramIndex++}`);
      values.push(purchasePrice);
    }
    if (notes !== undefined) {
      updates.push(`notes = $${paramIndex++}`);
      values.push(notes);
    }
    if (toolboxId !== undefined) {
      updates.push(`toolbox_id = $${paramIndex++}`);
      values.push(toolboxId);
    }

    if (updates.length === 0) {
      return badRequest('No fields to update');
    }

    values.push(toolId);

    const result = await queryOne<Tool>(
      `UPDATE tools SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING *`,
      values
    );

    if (!result) {
      return serverError('Failed to update tool');
    }

    const response = await toToolResponse(result);
    return success(response);
  } catch (error) {
    console.error('Error updating tool:', error);
    return serverError('Failed to update tool');
  }
}

// Delete a tool
export async function deleteTool(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Get the tool and check ownership
    const tool = await queryOne<Tool>(
      'SELECT * FROM tools WHERE id = $1',
      [toolId]
    );

    if (!tool) {
      return notFound('Tool not found');
    }

    const toolbox = await checkToolboxOwnership(tool.toolbox_id, currentUserId);
    if (!toolbox) {
      return forbidden('You do not own this tool');
    }

    // Delete tool (images cascade)
    await query('DELETE FROM tools WHERE id = $1', [toolId]);

    return noContent();
  } catch (error) {
    console.error('Error deleting tool:', error);
    return serverError('Failed to delete tool');
  }
}
