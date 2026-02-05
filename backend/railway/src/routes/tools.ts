import { Router, Request, Response, NextFunction } from 'express';
import { query, queryOne, queryReturning } from '../db';
import { requireUser, optionalAuth } from '../middleware/auth';
import { badRequest, notFound, forbidden, conflict } from '../middleware/errorHandler';
import { isValidUUID, isValidImageType } from '../utils/validation';
import { getPagination, paginate } from '../utils/pagination';
import { getUploadUrl, getPublicUrl, deleteImage, checkImageExists, generateImageKey } from '../services/r2';
import { Tool, ToolImage, ToolResponse, ToolImageResponse, Toolbox } from '../models/types';

export const toolRoutes = Router();

const MAX_IMAGES = 3;

// Get image URL
function getImageUrl(s3Key: string): string {
  return getPublicUrl(s3Key);
}

// Convert DB tool to response format
async function toToolResponse(tool: Tool): Promise<ToolResponse> {
  const imagesResult = await query<ToolImage>(
    'SELECT * FROM tool_images WHERE tool_id = $1 ORDER BY order_index',
    [tool.id]
  );

  const images: ToolImageResponse[] = imagesResult.rows.map((img) => ({
    id: img.id,
    url: getImageUrl(img.s3_key),
    orderIndex: img.order_index,
  }));

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

// Check toolbox ownership
async function checkToolboxOwnership(toolboxId: string, userId: string): Promise<Toolbox | null> {
  return queryOne<Toolbox>(
    'SELECT * FROM toolboxes WHERE id = $1 AND user_id = $2',
    [toolboxId, userId]
  );
}

// Check toolbox access
async function hasToolboxAccess(toolboxId: string, userId: string | null): Promise<boolean> {
  const toolbox = await queryOne<Toolbox>(
    'SELECT * FROM toolboxes WHERE id = $1',
    [toolboxId]
  );

  if (!toolbox) return false;
  if (userId === toolbox.user_id) return true;
  if (toolbox.visibility === 'public') return true;
  if (!userId) return false;

  const permission = await queryOne(
    'SELECT 1 FROM toolbox_permissions WHERE toolbox_id = $1 AND user_id = $2',
    [toolboxId, userId]
  );
  if (permission) return true;

  if (toolbox.visibility === 'buddies') {
    const buddy = await queryOne(
      'SELECT 1 FROM buddies WHERE user_id = $1 AND buddy_id = $2',
      [userId, toolbox.user_id]
    );
    return !!buddy;
  }

  return false;
}

// GET /api/tools/:id - Get a specific tool
toolRoutes.get('/:id', optionalAuth, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid tool ID');
    }

    // Get user ID if authenticated
    if (req.clerkUserId && !req.userId) {
      const user = await queryOne<{ id: string }>(
        'SELECT id FROM users WHERE clerk_id = $1',
        [req.clerkUserId]
      );
      if (user) req.userId = user.id;
    }

    const tool = await queryOne<Tool>(
      'SELECT * FROM tools WHERE id = $1',
      [id]
    );

    if (!tool) {
      throw notFound('Tool not found');
    }

    const hasAccess = await hasToolboxAccess(tool.toolbox_id, req.userId || null);
    if (!hasAccess) {
      throw forbidden('You do not have access to this tool');
    }

    const response = await toToolResponse(tool);
    res.json(response);
  } catch (error) {
    next(error);
  }
});

// PUT /api/tools/:id - Update a tool
toolRoutes.put('/:id', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid tool ID');
    }

    const tool = await queryOne<Tool>(
      'SELECT * FROM tools WHERE id = $1',
      [id]
    );

    if (!tool) {
      throw notFound('Tool not found');
    }

    const toolbox = await checkToolboxOwnership(tool.toolbox_id, req.userId!);
    if (!toolbox) {
      throw forbidden('You do not own this tool');
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
    } = req.body;

    // If moving to different toolbox, verify ownership
    if (toolboxId && toolboxId !== tool.toolbox_id) {
      const newToolbox = await checkToolboxOwnership(toolboxId, req.userId!);
      if (!newToolbox) {
        throw forbidden('You do not own the target toolbox');
      }
    }

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
      throw badRequest('No fields to update');
    }

    values.push(id);

    const result = await queryOne<Tool>(
      `UPDATE tools SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
       WHERE id = $${paramIndex}
       RETURNING *`,
      values
    );

    if (!result) {
      throw badRequest('Failed to update tool');
    }

    const response = await toToolResponse(result);
    res.json(response);
  } catch (error) {
    next(error);
  }
});

// DELETE /api/tools/:id - Delete a tool
toolRoutes.delete('/:id', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid tool ID');
    }

    const tool = await queryOne<Tool>(
      'SELECT * FROM tools WHERE id = $1',
      [id]
    );

    if (!tool) {
      throw notFound('Tool not found');
    }

    const toolbox = await checkToolboxOwnership(tool.toolbox_id, req.userId!);
    if (!toolbox) {
      throw forbidden('You do not own this tool');
    }

    // Delete images from R2
    const images = await query<ToolImage>(
      'SELECT * FROM tool_images WHERE tool_id = $1',
      [id]
    );

    for (const img of images.rows) {
      try {
        await deleteImage(img.s3_key);
      } catch (e) {
        console.error('Failed to delete image from R2:', e);
      }
    }

    await query('DELETE FROM tools WHERE id = $1', [id]);

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// POST /api/tools/:id/images/upload-url - Get presigned upload URL
toolRoutes.post('/:id/images/upload-url', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { contentType } = req.body;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid tool ID');
    }

    if (!contentType || !isValidImageType(contentType)) {
      throw badRequest('Invalid content type. Allowed: jpeg, png, webp, gif');
    }

    const tool = await queryOne<Tool>(
      'SELECT * FROM tools WHERE id = $1',
      [id]
    );

    if (!tool) {
      throw notFound('Tool not found');
    }

    const toolbox = await checkToolboxOwnership(tool.toolbox_id, req.userId!);
    if (!toolbox) {
      throw forbidden('You do not own this tool');
    }

    // Check current image count
    const imageCount = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM tool_images WHERE tool_id = $1',
      [id]
    );

    if (parseInt(imageCount?.count || '0') >= MAX_IMAGES) {
      throw conflict(`Maximum of ${MAX_IMAGES} images allowed per tool`);
    }

    const extension = contentType.split('/')[1];
    const key = generateImageKey(id, extension);
    const uploadUrl = await getUploadUrl(key, contentType);

    res.json({
      uploadUrl,
      key,
      expiresIn: 300,
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/tools/:id/images - Add image after upload
toolRoutes.post('/:id/images', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { key, orderIndex } = req.body;

    if (!isValidUUID(id)) {
      throw badRequest('Invalid tool ID');
    }

    if (!key) {
      throw badRequest('Image key is required');
    }

    const tool = await queryOne<Tool>(
      'SELECT * FROM tools WHERE id = $1',
      [id]
    );

    if (!tool) {
      throw notFound('Tool not found');
    }

    const toolbox = await checkToolboxOwnership(tool.toolbox_id, req.userId!);
    if (!toolbox) {
      throw forbidden('You do not own this tool');
    }

    // Check current image count
    const existingImages = await query<ToolImage>(
      'SELECT * FROM tool_images WHERE tool_id = $1 ORDER BY order_index',
      [id]
    );

    if (existingImages.rows.length >= MAX_IMAGES) {
      throw conflict(`Maximum of ${MAX_IMAGES} images allowed per tool`);
    }

    // Verify image exists in R2
    const exists = await checkImageExists(key);
    if (!exists) {
      throw badRequest('Image not found. Please upload the image first.');
    }

    // Determine order index
    let actualOrderIndex = orderIndex;
    if (actualOrderIndex === undefined || actualOrderIndex < 0) {
      const maxIndex = existingImages.rows.reduce(
        (max, img) => Math.max(max, img.order_index),
        -1
      );
      actualOrderIndex = maxIndex + 1;
    }

    if (actualOrderIndex >= MAX_IMAGES) {
      actualOrderIndex = MAX_IMAGES - 1;
    }

    const image = await queryReturning<ToolImage>(
      `INSERT INTO tool_images (tool_id, s3_key, s3_bucket, order_index)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [id, key, process.env.R2_BUCKET_NAME || 'toolkudu-images', actualOrderIndex]
    );

    if (!image) {
      throw badRequest('Failed to add image');
    }

    res.status(201).json({
      id: image.id,
      url: getImageUrl(image.s3_key),
      orderIndex: image.order_index,
    });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/tools/:id/images/:imageId - Delete an image
toolRoutes.delete('/:id/images/:imageId', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id, imageId } = req.params;

    if (!isValidUUID(id) || !isValidUUID(imageId)) {
      throw badRequest('Invalid ID');
    }

    const tool = await queryOne<Tool>(
      'SELECT * FROM tools WHERE id = $1',
      [id]
    );

    if (!tool) {
      throw notFound('Tool not found');
    }

    const toolbox = await checkToolboxOwnership(tool.toolbox_id, req.userId!);
    if (!toolbox) {
      throw forbidden('You do not own this tool');
    }

    const image = await queryOne<ToolImage>(
      'SELECT * FROM tool_images WHERE id = $1 AND tool_id = $2',
      [imageId, id]
    );

    if (!image) {
      throw notFound('Image not found');
    }

    // Delete from R2
    try {
      await deleteImage(image.s3_key);
    } catch (e) {
      console.error('Failed to delete from R2:', e);
    }

    await query('DELETE FROM tool_images WHERE id = $1', [imageId]);

    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

// GET /api/tools/shared - Get tools currently lent out
toolRoutes.get('/shared', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await query<{
      id: string;
      name: string;
      description: string | null;
      borrower_username: string;
      borrowed_at: Date;
    }>(
      `SELECT t.id, t.name, t.description, u.username as borrower_username, lh.borrowed_at
       FROM tools t
       INNER JOIN toolboxes tb ON tb.id = t.toolbox_id
       INNER JOIN lending_history lh ON lh.tool_id = t.id AND lh.returned_at IS NULL
       INNER JOIN users u ON u.id = lh.borrower_id
       WHERE tb.user_id = $1 AND t.is_available = false
       ORDER BY lh.borrowed_at DESC`,
      [req.userId]
    );

    res.json(result.rows.map((t) => ({
      id: t.id,
      name: t.name,
      description: t.description,
      borrowerUsername: t.borrower_username,
      borrowedAt: t.borrowed_at,
    })));
  } catch (error) {
    next(error);
  }
});

// GET /api/tools/borrowed - Get tools currently borrowed
toolRoutes.get('/borrowed', requireUser, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await query<{
      id: string;
      name: string;
      description: string | null;
      owner_username: string;
      borrowed_at: Date;
      lending_request_id: string;
    }>(
      `SELECT t.id, t.name, t.description, u.username as owner_username, lh.borrowed_at, lh.lending_request_id
       FROM lending_history lh
       INNER JOIN tools t ON t.id = lh.tool_id
       INNER JOIN users u ON u.id = lh.owner_id
       WHERE lh.borrower_id = $1 AND lh.returned_at IS NULL
       ORDER BY lh.borrowed_at DESC`,
      [req.userId]
    );

    res.json(result.rows.map((t) => ({
      id: t.id,
      name: t.name,
      description: t.description,
      ownerUsername: t.owner_username,
      borrowedAt: t.borrowed_at,
      lendingRequestId: t.lending_request_id,
    })));
  } catch (error) {
    next(error);
  }
});
