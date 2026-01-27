import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { S3 } from 'aws-sdk';
import { v4 as uuidv4 } from 'uuid';
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
import { Tool, ToolImage, Toolbox, AddImageInput } from '../models/tool';

const s3 = new S3();
const S3_BUCKET = process.env.S3_BUCKET || '';
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';
const MAX_IMAGES = 3;

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
): Promise<Toolbox | null> {
  return queryOne<Toolbox>(
    'SELECT * FROM toolboxes WHERE id = $1 AND user_id = $2',
    [toolboxId, userId]
  );
}

// Get image URL from S3 key
function getImageUrl(s3Key: string, bucket: string): string {
  return `https://${bucket}.s3.${AWS_REGION}.amazonaws.com/${s3Key}`;
}

// Get a presigned URL for uploading an image
export async function getUploadUrl(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');
    const body = parseBody<{ contentType: string; fileName?: string }>(event);

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    if (!body || !body.contentType) {
      return badRequest('Content type is required');
    }

    const { contentType, fileName } = body;

    // Validate content type
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowedTypes.includes(contentType)) {
      return badRequest('Invalid content type. Allowed: jpeg, png, webp, gif');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Get the tool and verify ownership
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

    // Check current image count
    const imageCount = await queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM tool_images WHERE tool_id = $1',
      [toolId]
    );

    if (parseInt(imageCount?.count || '0') >= MAX_IMAGES) {
      return conflict(`Maximum of ${MAX_IMAGES} images allowed per tool`);
    }

    // Generate S3 key
    const extension = contentType.split('/')[1];
    const s3Key = `tools/${toolId}/${uuidv4()}.${extension}`;

    // Generate presigned URL
    const uploadUrl = s3.getSignedUrl('putObject', {
      Bucket: S3_BUCKET,
      Key: s3Key,
      ContentType: contentType,
      Expires: 300, // 5 minutes
    });

    return success({
      uploadUrl,
      s3Key,
      expiresIn: 300,
    });
  } catch (error) {
    console.error('Error getting upload URL:', error);
    return serverError('Failed to generate upload URL');
  }
}

// Add an image to a tool (after uploading to S3)
export async function addImage(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');
    const body = parseBody<AddImageInput>(event);

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    if (!body || !body.s3Key) {
      return badRequest('S3 key is required');
    }

    const { s3Key, orderIndex } = body;

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Get the tool and verify ownership
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

    // Check current image count
    const existingImages = await query<ToolImage>(
      'SELECT * FROM tool_images WHERE tool_id = $1 ORDER BY order_index',
      [toolId]
    );

    if (existingImages.rows.length >= MAX_IMAGES) {
      return conflict(`Maximum of ${MAX_IMAGES} images allowed per tool`);
    }

    // Determine order index
    let actualOrderIndex = orderIndex;
    if (actualOrderIndex === undefined || actualOrderIndex < 0) {
      // Use next available index
      const maxIndex = existingImages.rows.reduce(
        (max, img) => Math.max(max, img.order_index),
        -1
      );
      actualOrderIndex = maxIndex + 1;
    }

    if (actualOrderIndex >= MAX_IMAGES) {
      actualOrderIndex = MAX_IMAGES - 1;
    }

    // Verify the S3 object exists
    try {
      await s3.headObject({ Bucket: S3_BUCKET, Key: s3Key }).promise();
    } catch {
      return badRequest('S3 object not found. Please upload the image first.');
    }

    // Create the image record
    const image = await queryReturning<ToolImage>(
      `INSERT INTO tool_images (tool_id, s3_key, s3_bucket, order_index)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [toolId, s3Key, S3_BUCKET, actualOrderIndex]
    );

    if (!image) {
      return serverError('Failed to add image');
    }

    return created({
      id: image.id,
      url: getImageUrl(image.s3_key, image.s3_bucket),
      orderIndex: image.order_index,
    });
  } catch (error) {
    console.error('Error adding image:', error);
    return serverError('Failed to add image');
  }
}

// Delete an image from a tool
export async function deleteImage(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const cognitoUser = await authenticate(event);
    const toolId = getPathParam(event, 'id');
    const imageId = getPathParam(event, 'imageId');

    if (!toolId || !isValidUUID(toolId)) {
      return badRequest('Invalid tool ID');
    }

    if (!imageId || !isValidUUID(imageId)) {
      return badRequest('Invalid image ID');
    }

    const currentUserId = await getCurrentUserId(cognitoUser.sub);
    if (!currentUserId) {
      return notFound('User not found');
    }

    // Get the tool and verify ownership
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

    // Get the image
    const image = await queryOne<ToolImage>(
      'SELECT * FROM tool_images WHERE id = $1 AND tool_id = $2',
      [imageId, toolId]
    );

    if (!image) {
      return notFound('Image not found');
    }

    // Delete from S3
    try {
      await s3
        .deleteObject({
          Bucket: image.s3_bucket,
          Key: image.s3_key,
        })
        .promise();
    } catch (s3Error) {
      console.error('Failed to delete S3 object:', s3Error);
      // Continue with database deletion even if S3 fails
    }

    // Delete from database
    await query('DELETE FROM tool_images WHERE id = $1', [imageId]);

    return noContent();
  } catch (error) {
    console.error('Error deleting image:', error);
    return serverError('Failed to delete image');
  }
}
