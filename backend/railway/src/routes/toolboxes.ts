import { Router, Request, Response, NextFunction } from 'express';
import { query, queryOne, queryReturning } from '../db';
import { requireUser, optionalAuth, attachUserId } from '../middleware/auth';
import { badRequest, notFound, forbidden } from '../middleware/errorHandler';
import { isValidUUID, isValidVisibility, VisibilityType } from '../utils/validation';
import { getPagination, paginate } from '../utils/pagination';
import { Toolbox, ToolboxResponse } from '../models/types';

export const toolboxRoutes = Router();

// Convert DB toolbox to response format
function toToolboxResponse(toolbox: Toolbox & { tool_count?: string }): ToolboxResponse {
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

// Check toolbox access
async function checkToolboxAccess(
  toolbox: Toolbox,
  currentUserId: string | null
): Promise<boolean> {
  if (currentUserId === toolbox.user_id) return true;
  if (toolbox.visibility === 'public') return true;
  if (!currentUserId) return false;

  const permission = await queryOne(
    'SELECT 1 FROM toolbox_permissions WHERE toolbox_id = $1 AND user_id = $2',
    [toolbox.id, currentUserId]
  );
  if (permission) return true;

  if (toolbox.visibility === 'buddies') {
    const buddy = await queryOne(
      'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
      [currentUserId, toolbox.user_id]
    );
    return !!buddy;
  }

  return false;
}

// GET /api/toolboxes - Get current user's toolboxes
toolboxRoutes.get('/', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { page, pageSize, offset } = getPagination(req);

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM toolboxes WHERE user_id = $1',
      [req.userId]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query<Toolbox & { tool_count: string }>(
      `SELECT tb.*,
        (SELECT COUNT(*) FROM tools WHERE toolbox_id = tb.id) as tool_count
       FROM toolboxes tb
       WHERE tb.user_id = $1
       ORDER BY tb.created_at DESC
       LIMIT $2 OFFSET $3`,
      [req.userId, pageSize, offset]
    );

    const toolboxes = result.rows.map(toToolboxResponse);
    res.json(paginate(toolboxes, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// POST /api/toolboxes - Create a new toolbox
toolboxRoutes.post('/', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { name, description, visibility, icon, color } = req.body;

    if (!name || typeof name !== 'string') {
      throw badRequest('Name is required');
    }

    const actualVisibility: VisibilityType = visibility && isValidVisibility(visibility)
      ? visibility
      : 'private';

    const toolbox = await queryReturning<Toolbox>(
      `INSERT INTO toolboxes (user_id, name, description, visibility, icon, color)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [req.userId, name, description || null, actualVisibility, icon || null, color || null]
    );

    if (!toolbox) {
      throw badRequest('Failed to create toolbox');
    }

    res.status(201).json(toToolboxResponse({ ...toolbox, tool_count: '0' }));
  } catch (error) {
    next(error);
  }
});

// GET /api/toolboxes/:id - Get a specific toolbox
toolboxRoutes.get('/:id', optionalAuth, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid toolbox ID');
    }

    // Try to get user ID if authenticated
    if (req.clerkUserId && !req.userId) {
      const user = await queryOne<{ id: string }>(
        'SELECT id FROM users WHERE clerk_id = $1',
        [req.clerkUserId]
      );
      if (user) req.userId = user.id;
    }

    const toolbox = await queryOne<Toolbox & { tool_count: string }>(
      `SELECT tb.*,
        (SELECT COUNT(*) FROM tools WHERE toolbox_id = tb.id) as tool_count
       FROM toolboxes tb
       WHERE tb.id = $1`,
      [id]
    );

    if (!toolbox) {
      throw notFound('Toolbox not found');
    }

    const hasAccess = await checkToolboxAccess(toolbox, req.userId || null);
    if (!hasAccess) {
      throw forbidden('You do not have access to this toolbox');
    }

    res.json(toToolboxResponse(toolbox));
  } catch (error) {
    next(error);
  }
});

// PUT /api/toolboxes/:id - Update a toolbox
toolboxRoutes.put('/:id', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid toolbox ID');
    }

    const existing = await queryOne<Toolbox>(
      'SELECT * FROM toolboxes WHERE id = $1',
      [id]
    );

    if (!existing) {
      throw notFound('Toolbox not found');
    }

    if (existing.user_id !== req.userId) {
      throw forbidden('You do not own this toolbox');
    }

    const { name, description, visibility, icon, color } = req.body;

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
    if (visibility !== undefined && isValidVisibility(visibility)) {
      updates.push(`visibility = $${paramIndex++}`);
      values.push(visibility);
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
      throw badRequest('No fields to update');
    }

    values.push(id);

    const result = await queryOne<Toolbox & { tool_count: string }>(
      `UPDATE toolboxes SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
       WHERE id = $${paramIndex}
       RETURNING *,
         (SELECT COUNT(*) FROM tools WHERE toolbox_id = toolboxes.id) as tool_count`,
      values
    );

    if (!result) {
      throw badRequest('Failed to update toolbox');
    }

    res.json(toToolboxResponse(result));
  } catch (error) {
    next(error);
  }
});

// DELETE /api/toolboxes/:id - Delete a toolbox
toolboxRoutes.delete('/:id', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid toolbox ID');
    }

    const existing = await queryOne<Toolbox>(
      'SELECT * FROM toolboxes WHERE id = $1',
      [id]
    );

    if (!existing) {
      throw notFound('Toolbox not found');
    }

    if (existing.user_id !== req.userId) {
      throw forbidden('You do not own this toolbox');
    }

    await query('DELETE FROM toolboxes WHERE id = $1', [id]);

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// GET /api/toolboxes/:id/permissions - Get toolbox permissions
toolboxRoutes.get('/:id/permissions', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid toolbox ID');
    }

    const toolbox = await queryOne<Toolbox>(
      'SELECT * FROM toolboxes WHERE id = $1',
      [id]
    );

    if (!toolbox) {
      throw notFound('Toolbox not found');
    }

    if (toolbox.user_id !== req.userId) {
      throw forbidden('You do not own this toolbox');
    }

    const result = await query(
      `SELECT tp.*, u.username, u.display_name, u.avatar_url
       FROM toolbox_permissions tp
       INNER JOIN users u ON u.id = tp.user_id
       WHERE tp.toolbox_id = $1`,
      [id]
    );

    res.json(result.rows);
  } catch (error) {
    next(error);
  }
});

// POST /api/toolboxes/:id/permissions - Add permission
toolboxRoutes.post('/:id/permissions', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { userId, permissionLevel } = req.body;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid toolbox ID');
    }

    if (!userId || !isValidUUID(userId)) {
      throw badRequest('Invalid user ID');
    }

    const toolbox = await queryOne<Toolbox>(
      'SELECT * FROM toolboxes WHERE id = $1',
      [id]
    );

    if (!toolbox) {
      throw notFound('Toolbox not found');
    }

    if (toolbox.user_id !== req.userId) {
      throw forbidden('You do not own this toolbox');
    }

    const result = await queryReturning(
      `INSERT INTO toolbox_permissions (toolbox_id, user_id, permission_level)
       VALUES ($1, $2, $3)
       ON CONFLICT (toolbox_id, user_id) DO UPDATE SET permission_level = $3
       RETURNING *`,
      [id, userId, permissionLevel || 'view']
    );

    res.status(201).json(result);
  } catch (error) {
    next(error);
  }
});

// GET /api/toolboxes/:id/tools - Get tools in a toolbox
toolboxRoutes.get('/:id/tools', optionalAuth, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { page, pageSize, offset } = getPagination(req);

    if (!isValidUUID(id)) {
      throw badRequest('Invalid toolbox ID');
    }

    // Get user ID if authenticated
    if (req.clerkUserId && !req.userId) {
      const user = await queryOne<{ id: string }>(
        'SELECT id FROM users WHERE clerk_id = $1',
        [req.clerkUserId]
      );
      if (user) req.userId = user.id;
    }

    const toolbox = await queryOne<Toolbox>(
      'SELECT * FROM toolboxes WHERE id = $1',
      [id]
    );

    if (!toolbox) {
      throw notFound('Toolbox not found');
    }

    const hasAccess = await checkToolboxAccess(toolbox, req.userId || null);
    if (!hasAccess) {
      throw forbidden('You do not have access to this toolbox');
    }

    const countResult = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM tools WHERE toolbox_id = $1',
      [id]
    );
    const total = parseInt(countResult?.count || '0');

    const result = await query(
      `SELECT t.*,
        (SELECT json_agg(json_build_object('id', ti.id, 's3_key', ti.s3_key, 'order_index', ti.order_index))
         FROM tool_images ti WHERE ti.tool_id = t.id ORDER BY ti.order_index) as images,
        EXISTS(SELECT 1 FROM tool_trackers tt WHERE tt.tool_id = t.id AND tt.is_active = true) as has_tracker
       FROM tools t
       WHERE t.toolbox_id = $1
       ORDER BY t.name
       LIMIT $2 OFFSET $3`,
      [id, pageSize, offset]
    );

    const tools = result.rows.map((tool: any) => ({
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
      images: (tool.images || []).map((img: any) => ({
        id: img.id,
        url: `${process.env.R2_PUBLIC_URL}/${img.s3_key}`,
        orderIndex: img.order_index,
      })),
      hasTracker: tool.has_tracker,
      createdAt: tool.created_at,
      updatedAt: tool.updated_at,
    }));

    res.json(paginate(tools, total, page, pageSize));
  } catch (error) {
    next(error);
  }
});

// POST /api/toolboxes/:id/tools - Create a tool in a toolbox
toolboxRoutes.post('/:id/tools', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id: toolboxId } = req.params;

    if (!isValidUUID(toolboxId)) {
      throw badRequest('Invalid toolbox ID');
    }

    const toolbox = await queryOne<Toolbox>(
      'SELECT * FROM toolboxes WHERE id = $1 AND user_id = $2',
      [toolboxId, req.userId]
    );

    if (!toolbox) {
      throw forbidden('You do not own this toolbox');
    }

    const { name, description, category, brand, model, serialNumber, purchaseDate, purchasePrice, notes } = req.body;

    if (!name || typeof name !== 'string') {
      throw badRequest('Name is required');
    }

    const tool = await queryReturning(
      `INSERT INTO tools (toolbox_id, name, description, category, brand, model, serial_number, purchase_date, purchase_price, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [toolboxId, name, description || null, category || null, brand || null, model || null,
       serialNumber || null, purchaseDate || null, purchasePrice || null, notes || null]
    );

    if (!tool) {
      throw badRequest('Failed to create tool');
    }

    res.status(201).json({
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
      images: [],
      hasTracker: false,
      createdAt: tool.created_at,
      updatedAt: tool.updated_at,
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/toolboxes/:id/permissions/:userId - Remove permission
toolboxRoutes.delete('/:id/permissions/:userId', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id, userId } = req.params;

    if (!isValidUUID(id) || !isValidUUID(userId)) {
      throw badRequest('Invalid ID');
    }

    const toolbox = await queryOne<Toolbox>(
      'SELECT * FROM toolboxes WHERE id = $1',
      [id]
    );

    if (!toolbox) {
      throw notFound('Toolbox not found');
    }

    if (toolbox.user_id !== req.userId) {
      throw forbidden('You do not own this toolbox');
    }

    await query(
      'DELETE FROM toolbox_permissions WHERE toolbox_id = $1 AND user_id = $2',
      [id, userId]
    );

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});
