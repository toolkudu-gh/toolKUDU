# ToolKUDU Railway Migration Plan

## Overview

This document provides a step-by-step migration plan from AWS (Lambda + API Gateway + RDS + Cognito + S3) to Railway + Clerk + Cloudflare R2.

### Current AWS Architecture
```
┌─────────────────────────────────────────────────────────────┐
│  AWS                                                        │
│  ├── tool-service (Lambda + API Gateway)                   │
│  │   └── 14 endpoints (toolboxes, tools, images)           │
│  ├── user-service (Lambda + API Gateway)                   │
│  │   └── 15 endpoints (profile, follows, buddies)          │
│  ├── location-service (Lambda + API Gateway)               │
│  │   └── 6 endpoints (trackers, location history)          │
│  ├── sharing-service (Lambda + API Gateway)                │
│  │   └── 12 endpoints (permissions, lending)               │
│  ├── RDS PostgreSQL (db.t3.micro)                          │
│  ├── Cognito (User Pool + Client)                          │
│  ├── S3 (Tool Images)                                      │
│  ├── VPC + Security Groups                                 │
│  └── SNS (Notifications)                                   │
└─────────────────────────────────────────────────────────────┘
```

### Target Railway Architecture
```
┌─────────────────────────────────────────────────────────────┐
│  Railway                                                    │
│  ├── toolkudu-frontend (Flutter Web static)                │
│  ├── toolkudu-api (Consolidated Express.js service)        │
│  │   └── All 47 endpoints under /api/*                     │
│  └── PostgreSQL (Railway managed)                          │
├─────────────────────────────────────────────────────────────┤
│  External Services                                          │
│  ├── Clerk (Authentication)                                │
│  └── Cloudflare R2 (Image Storage)                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Pre-Migration Preparation (Day 1-2)

### 1.1 Create Accounts

**Railway**
1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub (recommended for automatic deployments)
3. Add payment method ($5 initial credit available)

**Clerk**
1. Go to [clerk.com](https://clerk.com)
2. Sign up for free tier (10K MAU included)
3. Create application: "ToolKUDU"
4. Note down:
   - `CLERK_PUBLISHABLE_KEY`
   - `CLERK_SECRET_KEY`

**Cloudflare**
1. Go to [cloudflare.com](https://cloudflare.com)
2. Sign up/login
3. Navigate to R2 Object Storage
4. Create bucket: `toolkudu-images`
5. Generate API token with R2 read/write permissions
6. Note down:
   - `CLOUDFLARE_ACCOUNT_ID`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`
   - `R2_BUCKET_NAME` (toolkudu-images)

### 1.2 Export Current Data

**Database Backup**
```bash
# From AWS RDS (requires pg_dump access)
pg_dump -h <RDS_ENDPOINT> -U toolkudu_admin -d toolkudu -F c -f toolkudu_backup.dump

# Or use AWS RDS snapshot feature in console
```

**S3 Images Backup**
```bash
# Install AWS CLI if not present
aws s3 sync s3://toolkudu-images-dev-<account-id>/ ./backup/images/
```

**Export Cognito Users**
```bash
# Using AWS CLI
aws cognito-idp list-users \
  --user-pool-id <USER_POOL_ID> \
  --output json > cognito_users.json
```

### 1.3 Create New Project Structure

Create a new backend structure for Railway:

```
backend/
├── railway/                    # New Railway-specific code
│   ├── src/
│   │   ├── index.ts           # Express app entry point
│   │   ├── middleware/
│   │   │   ├── auth.ts        # Clerk auth middleware
│   │   │   └── cors.ts        # CORS configuration
│   │   ├── routes/
│   │   │   ├── tools.ts       # Tool routes
│   │   │   ├── users.ts       # User routes
│   │   │   ├── location.ts    # Location routes
│   │   │   ├── sharing.ts     # Sharing routes
│   │   │   └── health.ts      # Health check
│   │   ├── services/
│   │   │   └── r2.ts          # Cloudflare R2 service
│   │   └── db/
│   │       └── index.ts       # Database connection
│   ├── package.json
│   ├── tsconfig.json
│   └── Dockerfile             # For Railway deployment
└── services/                   # Keep existing Lambda code as reference
```

---

## Phase 2: Backend Conversion (Day 3-7)

### 2.1 Create Express.js Application

**backend/railway/package.json**
```json
{
  "name": "toolkudu-api",
  "version": "1.0.0",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "db:migrate": "prisma migrate deploy"
  },
  "dependencies": {
    "@clerk/clerk-sdk-node": "^5.0.0",
    "@aws-sdk/client-s3": "^3.500.0",
    "@aws-sdk/s3-request-presigner": "^3.500.0",
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "dotenv": "^16.4.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.11.0",
    "@types/pg": "^8.10.9",
    "@types/cors": "^2.8.17",
    "typescript": "^5.3.0",
    "tsx": "^4.7.0"
  }
}
```

**backend/railway/src/index.ts**
```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { clerkMiddleware, requireAuth } from '@clerk/clerk-sdk-node';
import { toolRoutes } from './routes/tools';
import { userRoutes } from './routes/users';
import { locationRoutes } from './routes/location';
import { sharingRoutes } from './routes/sharing';
import { healthRoutes } from './routes/health';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
}));
app.use(express.json());
app.use(clerkMiddleware());

// Routes
app.use('/api/health', healthRoutes);
app.use('/api/toolboxes', requireAuth(), toolRoutes);
app.use('/api/tools', requireAuth(), toolRoutes);
app.use('/api/users', userRoutes);
app.use('/api/trackers', requireAuth(), locationRoutes);
app.use('/api/lending', requireAuth(), sharingRoutes);

// Error handler
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`ToolKUDU API running on port ${PORT}`);
});
```

### 2.2 Convert Lambda Handlers to Express Routes

Each Lambda handler converts to an Express route. Example conversion:

**Before (Lambda - tool-service/src/handlers/tools.ts):**
```typescript
export const getTools = async (event: APIGatewayProxyEvent) => {
  const toolboxId = event.pathParameters?.toolboxId;
  const tools = await db.query('SELECT * FROM tools WHERE toolbox_id = $1', [toolboxId]);
  return { statusCode: 200, body: JSON.stringify(tools.rows) };
};
```

**After (Express - railway/src/routes/tools.ts):**
```typescript
import { Router } from 'express';
import { db } from '../db';

export const toolRoutes = Router();

toolRoutes.get('/toolboxes/:toolboxId/tools', async (req, res) => {
  try {
    const { toolboxId } = req.params;
    const tools = await db.query('SELECT * FROM tools WHERE toolbox_id = $1', [toolboxId]);
    res.json(tools.rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to get tools' });
  }
});
```

### 2.3 Endpoint Mapping

| Lambda Service | Lambda Path | Express Route |
|----------------|-------------|---------------|
| **tool-service** | | |
| getToolboxes | GET /toolboxes | GET /api/toolboxes |
| createToolbox | POST /toolboxes | POST /api/toolboxes |
| getToolbox | GET /toolboxes/{id} | GET /api/toolboxes/:id |
| updateToolbox | PUT /toolboxes/{id} | PUT /api/toolboxes/:id |
| deleteToolbox | DELETE /toolboxes/{id} | DELETE /api/toolboxes/:id |
| getTools | GET /toolboxes/{id}/tools | GET /api/toolboxes/:id/tools |
| createTool | POST /toolboxes/{id}/tools | POST /api/toolboxes/:id/tools |
| getTool | GET /tools/{id} | GET /api/tools/:id |
| updateTool | PUT /tools/{id} | PUT /api/tools/:id |
| deleteTool | DELETE /tools/{id} | DELETE /api/tools/:id |
| getUploadUrl | POST /tools/{id}/images/upload-url | POST /api/tools/:id/images/upload-url |
| addImage | POST /tools/{id}/images | POST /api/tools/:id/images |
| deleteImage | DELETE /tools/{id}/images/{imageId} | DELETE /api/tools/:id/images/:imageId |
| getUserToolboxes | GET /users/{userId}/toolboxes | GET /api/users/:userId/toolboxes |
| **user-service** | | |
| getProfile | GET /users/me | GET /api/users/me |
| updateProfile | PUT /users/me | PUT /api/users/me |
| getUserById | GET /users/{id} | GET /api/users/:id |
| searchUsers | GET /users/search | GET /api/users/search |
| followUser | POST /users/{id}/follow | POST /api/users/:id/follow |
| unfollowUser | DELETE /users/{id}/follow | DELETE /api/users/:id/follow |
| getFollowers | GET /users/me/followers | GET /api/users/me/followers |
| getFollowing | GET /users/me/following | GET /api/users/me/following |
| sendBuddyRequest | POST /users/{id}/buddy-request | POST /api/users/:id/buddy-request |
| respondToBuddyRequest | PUT /buddy-requests/{id} | PUT /api/buddy-requests/:id |
| getBuddyRequests | GET /buddy-requests | GET /api/buddy-requests |
| getBuddies | GET /users/me/buddies | GET /api/users/me/buddies |
| removeBuddy | DELETE /users/me/buddies/{id} | DELETE /api/users/me/buddies/:id |
| syncUser | POST /users/sync | POST /api/users/sync |
| **location-service** | | |
| getTrackers | GET /trackers | GET /api/trackers |
| getToolLocation | GET /tools/{id}/location | GET /api/tools/:id/location |
| addTracker | POST /tools/{id}/tracker | POST /api/tools/:id/tracker |
| updateTracker | PUT /tools/{id}/tracker | PUT /api/tools/:id/tracker |
| removeTracker | DELETE /tools/{id}/tracker | DELETE /api/tools/:id/tracker |
| getLocationHistory | GET /tools/{id}/location/history | GET /api/tools/:id/location/history |
| **sharing-service** | | |
| getPermissions | GET /toolboxes/{id}/permissions | GET /api/toolboxes/:id/permissions |
| updatePermissions | PUT /toolboxes/{id}/permissions | PUT /api/toolboxes/:id/permissions |
| addPermission | POST /toolboxes/{id}/permissions | POST /api/toolboxes/:id/permissions |
| removePermission | DELETE /toolboxes/{id}/permissions/{userId} | DELETE /api/toolboxes/:id/permissions/:userId |
| requestLend | POST /tools/{id}/lend-request | POST /api/tools/:id/lend-request |
| getIncomingRequests | GET /lending/incoming | GET /api/lending/incoming |
| getOutgoingRequests | GET /lending/outgoing | GET /api/lending/outgoing |
| respondToRequest | PUT /lending/{id}/respond | PUT /api/lending/:id/respond |
| returnTool | POST /lending/{id}/return | POST /api/lending/:id/return |
| getLendingHistory | GET /lending/history | GET /api/lending/history |
| getSharedTools | GET /tools/shared | GET /api/tools/shared |
| getBorrowedTools | GET /tools/borrowed | GET /api/tools/borrowed |

### 2.4 Auth Middleware (Clerk)

**backend/railway/src/middleware/auth.ts**
```typescript
import { ClerkExpressRequireAuth } from '@clerk/clerk-sdk-node';
import { Request, Response, NextFunction } from 'express';

// Clerk auth middleware
export const requireAuth = ClerkExpressRequireAuth();

// Extract user ID from Clerk session
export const getUserId = (req: Request): string | null => {
  return req.auth?.userId || null;
};

// Optional auth (for public routes that can have auth)
export const optionalAuth = (req: Request, res: Response, next: NextFunction) => {
  // Clerk middleware already attached auth if present
  next();
};
```

### 2.5 Storage Service (Cloudflare R2)

**backend/railway/src/services/r2.ts**
```typescript
import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const r2Client = new S3Client({
  region: 'auto',
  endpoint: `https://${process.env.CLOUDFLARE_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID!,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
  },
});

const BUCKET = process.env.R2_BUCKET_NAME!;
const PUBLIC_URL = process.env.R2_PUBLIC_URL!; // e.g., https://images.toolkudu.app

export async function getUploadUrl(key: string, contentType: string): Promise<string> {
  const command = new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    ContentType: contentType,
  });
  return getSignedUrl(r2Client, command, { expiresIn: 3600 });
}

export async function deleteImage(key: string): Promise<void> {
  const command = new DeleteObjectCommand({
    Bucket: BUCKET,
    Key: key,
  });
  await r2Client.send(command);
}

export function getPublicUrl(key: string): string {
  return `${PUBLIC_URL}/${key}`;
}
```

### 2.6 Database Connection

**backend/railway/src/db/index.ts**
```typescript
import { Pool } from 'pg';

export const db = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

// Test connection on startup
db.query('SELECT NOW()')
  .then(() => console.log('Database connected'))
  .catch(err => console.error('Database connection error:', err));
```

### 2.7 Dockerfile

**backend/railway/Dockerfile**
```dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source
COPY . .

# Build TypeScript
RUN npm run build

# Expose port
EXPOSE 3000

# Start server
CMD ["npm", "start"]
```

---

## Phase 3: Railway Setup & Deployment (Day 8-9)

### 3.1 Create Railway Project

1. Go to [railway.app/new](https://railway.app/new)
2. Click "Deploy from GitHub repo"
3. Select your ToolKUDU repository
4. Railway will auto-detect the project

### 3.2 Add PostgreSQL Database

1. In Railway dashboard, click "+ New"
2. Select "Database" → "PostgreSQL"
3. Railway provisions a PostgreSQL instance
4. Copy the `DATABASE_URL` from the Variables tab

### 3.3 Configure Services

**API Service Configuration:**

In Railway dashboard, create a new service for the backend:

1. Click "+ New" → "GitHub Repo"
2. Select repo and set root directory to `backend/railway`
3. Add environment variables:

```env
# Database (auto-linked if using Railway PostgreSQL)
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Clerk Authentication
CLERK_PUBLISHABLE_KEY=pk_live_xxx
CLERK_SECRET_KEY=sk_live_xxx

# Cloudflare R2
CLOUDFLARE_ACCOUNT_ID=xxx
R2_ACCESS_KEY_ID=xxx
R2_SECRET_ACCESS_KEY=xxx
R2_BUCKET_NAME=toolkudu-images
R2_PUBLIC_URL=https://images.toolkudu.app

# App
NODE_ENV=production
ALLOWED_ORIGINS=https://toolkudu.app,https://www.toolkudu.app
```

4. Set build command: `npm run build`
5. Set start command: `npm start`
6. Railway auto-deploys on git push

### 3.4 Add Frontend Service (Flutter Web)

1. Click "+ New" → "GitHub Repo"
2. Select repo and set root directory to `frontend`
3. Add build command:
```bash
flutter pub get && flutter build web --release
```
4. Set output directory: `build/web`
5. Railway serves as static site

**Alternative: Use Nixpacks for Flutter**

Create `frontend/nixpacks.toml`:
```toml
[phases.setup]
cmds = [
  "curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz | tar -xJ",
  "export PATH=\"$PATH:$(pwd)/flutter/bin\"",
  "flutter doctor"
]

[phases.build]
cmds = [
  "export PATH=\"$PATH:$(pwd)/flutter/bin\"",
  "flutter pub get",
  "flutter build web --release"
]

[start]
cmd = "npx serve build/web -s"
```

### 3.5 Migrate Database

**Option A: Direct pg_dump/pg_restore**
```bash
# Export from AWS RDS
pg_dump -h <RDS_ENDPOINT> -U toolkudu_admin -d toolkudu -F c -f backup.dump

# Import to Railway (get connection string from Railway dashboard)
pg_restore -d "<RAILWAY_DATABASE_URL>" backup.dump
```

**Option B: Using Railway CLI**
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link project
railway link

# Open database shell
railway run psql

# Then run your SQL migrations
```

### 3.6 Configure Custom Domain

1. In Railway dashboard, go to your API service
2. Click "Settings" → "Networking" → "Custom Domain"
3. Add: `api.toolkudu.app`
4. Add DNS records to your domain registrar:
   - Type: CNAME
   - Name: api
   - Value: (Railway provides this)

5. Repeat for frontend: `toolkudu.app` and `www.toolkudu.app`

---

## Phase 4: Auth Migration (Day 10-11)

### 4.1 Clerk Setup

**Frontend Configuration (Flutter)**

Update `frontend/lib/core/services/auth_service.dart`:

```dart
import 'package:clerk_flutter/clerk_flutter.dart';

class AuthService {
  static final ClerkAuth _clerk = ClerkAuth(
    publishableKey: const String.fromEnvironment('CLERK_PUBLISHABLE_KEY'),
  );

  Future<User?> signInWithGoogle() async {
    try {
      await _clerk.signIn.authenticateWithOAuth(
        strategy: OAuthStrategy.google,
      );
      return _clerk.user;
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    await _clerk.signIn.create(
      identifier: email,
      strategy: SignInStrategy.emailLink,
    );
  }

  Future<void> signOut() async {
    await _clerk.signOut();
  }

  Stream<User?> get userChanges => _clerk.userChanges;

  User? get currentUser => _clerk.user;

  String? get token => _clerk.session?.lastToken;
}
```

### 4.2 User Migration Strategy

**Option A: Lazy Migration (Recommended)**

Users re-register with Clerk on first login. Match by email:

```typescript
// In syncUser endpoint
async function syncUser(req: Request, res: Response) {
  const clerkUserId = req.auth?.userId;
  const clerkUser = await clerkClient.users.getUser(clerkUserId);

  // Check if user exists in database by email
  const existingUser = await db.query(
    'SELECT * FROM users WHERE email = $1',
    [clerkUser.emailAddresses[0].emailAddress]
  );

  if (existingUser.rows.length > 0) {
    // Link Clerk ID to existing user
    await db.query(
      'UPDATE users SET clerk_id = $1 WHERE id = $2',
      [clerkUserId, existingUser.rows[0].id]
    );
    return res.json(existingUser.rows[0]);
  }

  // Create new user
  const newUser = await db.query(
    `INSERT INTO users (clerk_id, email, username, display_name)
     VALUES ($1, $2, $3, $4) RETURNING *`,
    [clerkUserId, clerkUser.emailAddresses[0].emailAddress,
     generateUsername(clerkUser.emailAddresses[0].emailAddress),
     clerkUser.firstName || 'User']
  );

  return res.json(newUser.rows[0]);
}
```

**Option B: Bulk Migration**

Import Cognito users to Clerk using Clerk's API:

```typescript
import { clerkClient } from '@clerk/clerk-sdk-node';
import cognitoUsers from './cognito_users.json';

async function migrateUsers() {
  for (const user of cognitoUsers.Users) {
    try {
      await clerkClient.users.createUser({
        emailAddress: [user.Attributes.find(a => a.Name === 'email')?.Value],
        username: user.Username,
        skipPasswordRequirement: true, // Users reset password on first login
      });
      console.log(`Migrated: ${user.Username}`);
    } catch (error) {
      console.error(`Failed: ${user.Username}`, error);
    }
  }
}
```

### 4.3 Database Schema Update

Add Clerk ID column:

```sql
-- Migration to add Clerk ID
ALTER TABLE users ADD COLUMN clerk_id VARCHAR(255) UNIQUE;
CREATE INDEX idx_users_clerk_id ON users(clerk_id);

-- Keep cognito_id for reference during migration
-- ALTER TABLE users DROP COLUMN cognito_id; -- After migration complete
```

---

## Phase 5: Storage Migration (Day 12)

### 5.1 Migrate Images to Cloudflare R2

```bash
# Using rclone (recommended for large migrations)
# Install rclone: https://rclone.org/install/

# Configure S3 source
rclone config
# Name: aws
# Type: s3
# Provider: AWS
# Access Key/Secret: (your AWS credentials)

# Configure R2 destination
# Name: r2
# Type: s3
# Provider: Cloudflare
# Access Key/Secret: (your R2 credentials)
# Endpoint: https://<account-id>.r2.cloudflarestorage.com

# Sync images
rclone sync aws:toolkudu-images-dev-<account-id> r2:toolkudu-images --progress
```

### 5.2 Set Up R2 Public Access

1. In Cloudflare dashboard → R2 → toolkudu-images bucket
2. Go to "Settings" → "Public Access"
3. Enable and configure custom domain: `images.toolkudu.app`
4. Add DNS: CNAME `images` → (Cloudflare provides value)

### 5.3 Update Image URLs in Database

```sql
-- Update existing image URLs from S3 to R2
UPDATE tool_images
SET url = REPLACE(url,
  'https://toolkudu-images-dev-xxx.s3.amazonaws.com',
  'https://images.toolkudu.app'
);
```

---

## Phase 6: Frontend Updates (Day 13-14)

### 6.1 Update API Base URL

**frontend/lib/core/config/environment.dart**
```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.toolkudu.app/api',
  );

  static const String clerkPublishableKey = String.fromEnvironment(
    'CLERK_PUBLISHABLE_KEY',
  );
}
```

### 6.2 Update Auth Provider

Replace Cognito/AWS Amplify with Clerk:

```dart
// frontend/lib/core/providers/auth_provider.dart
import 'package:clerk_flutter/clerk_flutter.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> initialize() async {
    // Clerk handles session restoration automatically
    _user = ClerkAuth.instance.user;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ClerkAuth.instance.signIn.authenticateWithOAuth(
        strategy: OAuthStrategy.google,
      );
      _user = ClerkAuth.instance.user;

      // Sync user with backend
      await _syncUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncUser() async {
    final token = ClerkAuth.instance.session?.lastToken;
    await http.post(
      Uri.parse('${Environment.apiBaseUrl}/users/sync'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
```

### 6.3 Update HTTP Client

Ensure all API calls use Clerk token:

```dart
// frontend/lib/core/services/api_client.dart
class ApiClient {
  Future<Map<String, String>> get _headers async {
    final token = ClerkAuth.instance.session?.lastToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<T> get<T>(String path) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}$path'),
      headers: await _headers,
    );
    // ... handle response
  }
}
```

---

## Phase 7: Testing & Validation (Day 15-16)

### 7.1 API Testing Checklist

Test each endpoint category:

**Tools & Toolboxes**
- [ ] GET /api/toolboxes - List user's toolboxes
- [ ] POST /api/toolboxes - Create toolbox
- [ ] GET /api/toolboxes/:id - Get single toolbox
- [ ] PUT /api/toolboxes/:id - Update toolbox
- [ ] DELETE /api/toolboxes/:id - Delete toolbox
- [ ] GET /api/toolboxes/:id/tools - List tools
- [ ] POST /api/toolboxes/:id/tools - Create tool
- [ ] GET /api/tools/:id - Get single tool
- [ ] PUT /api/tools/:id - Update tool
- [ ] DELETE /api/tools/:id - Delete tool
- [ ] POST /api/tools/:id/images/upload-url - Get upload URL
- [ ] POST /api/tools/:id/images - Add image
- [ ] DELETE /api/tools/:id/images/:imageId - Delete image

**Users & Buddies**
- [ ] GET /api/users/me - Get current user
- [ ] PUT /api/users/me - Update profile
- [ ] GET /api/users/:id - Get user by ID
- [ ] GET /api/users/search - Search users
- [ ] POST /api/users/:id/buddy-request - Send buddy request
- [ ] PUT /api/buddy-requests/:id - Accept/decline
- [ ] GET /api/users/me/buddies - List buddies
- [ ] DELETE /api/users/me/buddies/:id - Remove buddy

**Sharing & Lending**
- [ ] POST /api/tools/:id/lend-request - Request to borrow
- [ ] GET /api/lending/incoming - Incoming requests
- [ ] GET /api/lending/outgoing - Outgoing requests
- [ ] PUT /api/lending/:id/respond - Accept/decline
- [ ] POST /api/lending/:id/return - Return tool
- [ ] GET /api/tools/shared - Currently shared
- [ ] GET /api/tools/borrowed - Currently borrowed

### 7.2 Frontend Testing Checklist

- [ ] User registration flow
- [ ] User login (Google, Magic Link)
- [ ] Profile view and edit
- [ ] Toolbox creation
- [ ] Tool creation with image upload
- [ ] Tool search (location-based)
- [ ] Buddy request flow
- [ ] Tool borrow request flow
- [ ] Responsive layout (mobile/tablet/desktop)

### 7.3 Performance Testing

```bash
# Basic load test with hey
hey -n 1000 -c 50 https://api.toolkudu.app/api/health

# Expected: <200ms p99 latency
```

---

## Phase 8: Cutover Strategy (Day 17)

### 8.1 Pre-Cutover Checklist

- [ ] All API endpoints tested and working
- [ ] Database migration verified
- [ ] Auth migration tested with test accounts
- [ ] Images accessible from R2
- [ ] DNS TTL lowered to 300 seconds (5 min)
- [ ] Rollback plan documented

### 8.2 Cutover Steps

**Option A: DNS Cutover (Recommended)**

1. **T-24h**: Lower DNS TTL to 300 seconds
2. **T-1h**: Final database sync from AWS to Railway
3. **T-0**: Update DNS records:
   - `api.toolkudu.app` → Railway CNAME
   - `toolkudu.app` → Railway CNAME
4. **T+5m**: Verify new endpoints responding
5. **T+1h**: Monitor for errors
6. **T+24h**: Increase DNS TTL back to normal

**Option B: Blue-Green with Feature Flag**

1. Deploy Railway backend at `api-new.toolkudu.app`
2. Add feature flag in frontend to toggle API URL
3. Roll out to 10% of users
4. Monitor for 24 hours
5. Gradually increase to 100%
6. Update DNS when stable

### 8.3 Rollback Plan

If issues arise within first 24 hours:

1. Revert DNS to AWS endpoints
2. DNS propagation: ~5-15 minutes with 300s TTL
3. AWS infrastructure remains running until confirmed stable

---

## Phase 9: Post-Migration Cleanup (Day 18-20)

### 9.1 AWS Teardown (After 7 Days Stable)

**Order of teardown:**
1. Delete Lambda functions (no ongoing cost)
2. Delete API Gateway (minimal cost)
3. Delete Cognito User Pool (no ongoing cost)
4. Empty and delete S3 bucket (storage cost)
5. Delete RDS instance (significant cost savings)
6. Delete VPC resources (Security Groups, Subnets)
7. Delete CloudFormation stacks

**Commands:**
```bash
# Delete S3 bucket
aws s3 rb s3://toolkudu-images-dev-xxx --force

# Delete RDS (after final backup)
aws rds delete-db-instance \
  --db-instance-identifier toolkudu-db-dev \
  --skip-final-snapshot

# Delete Cognito User Pool
aws cognito-idp delete-user-pool \
  --user-pool-id <USER_POOL_ID>

# Delete CloudFormation stacks
sls remove --stage dev  # For each service
```

### 9.2 Documentation Updates

- [ ] Update CLAUDE.md with new architecture
- [ ] Update README with Railway deployment info
- [ ] Archive old serverless.yml files
- [ ] Update environment variable documentation

### 9.3 Monitoring Setup

**Railway built-in monitoring:**
- CPU/Memory usage per service
- Request logs
- Deploy logs

**Add external monitoring (optional):**
- Sentry for error tracking
- Better Stack for uptime monitoring

---

## Cost Comparison

| Service | AWS Monthly | Railway Monthly |
|---------|-------------|-----------------|
| Compute (Lambda/Services) | ~$15-30 | ~$10-15 |
| Database (RDS/Railway PG) | ~$15-20 | ~$7-10 |
| Auth (Cognito/Clerk) | ~$0-5 | $0 (free tier) |
| Storage (S3/R2) | ~$5-10 | $0 (free tier) |
| **Total** | **~$35-65/month** | **~$17-25/month** |

**Savings: ~50%** plus significant reduction in operational complexity.

---

## Timeline Summary

| Day | Phase | Tasks |
|-----|-------|-------|
| 1-2 | Preparation | Create accounts, export data, plan structure |
| 3-7 | Backend Conversion | Convert Lambda → Express, set up auth/storage |
| 8-9 | Railway Setup | Deploy services, configure database |
| 10-11 | Auth Migration | Clerk integration, user migration |
| 12 | Storage Migration | S3 → R2 migration |
| 13-14 | Frontend Updates | Update API URLs, auth integration |
| 15-16 | Testing | Full E2E testing |
| 17 | Cutover | DNS switch, go live |
| 18-20 | Cleanup | AWS teardown, documentation |

**Total: ~3 weeks**

---

## Files to Create/Modify

### New Files (Railway Backend)
- `backend/railway/package.json`
- `backend/railway/tsconfig.json`
- `backend/railway/Dockerfile`
- `backend/railway/src/index.ts`
- `backend/railway/src/db/index.ts`
- `backend/railway/src/middleware/auth.ts`
- `backend/railway/src/services/r2.ts`
- `backend/railway/src/routes/tools.ts`
- `backend/railway/src/routes/users.ts`
- `backend/railway/src/routes/location.ts`
- `backend/railway/src/routes/sharing.ts`
- `backend/railway/src/routes/health.ts`

### Modify (Frontend)
- `frontend/lib/core/services/auth_service.dart` - Replace Cognito with Clerk
- `frontend/lib/core/providers/auth_provider.dart` - Update auth logic
- `frontend/lib/core/services/api_client.dart` - Update base URL
- `frontend/lib/core/config/environment.dart` - Add Clerk keys
- `frontend/pubspec.yaml` - Add clerk_flutter dependency

### Archive (Old AWS)
- `backend/services/*/serverless.yml` - Keep for reference
- `backend/infrastructure/serverless.yml` - Keep for reference

---

## Support Resources

- [Railway Documentation](https://docs.railway.app/)
- [Clerk Flutter SDK](https://clerk.com/docs/quickstarts/flutter)
- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)
