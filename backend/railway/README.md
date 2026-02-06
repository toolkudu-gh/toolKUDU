# ToolKUDU API - Railway Backend

Express.js API for ToolKUDU, designed for Railway deployment.

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment template
cp .env.example .env
# Edit .env with your values

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string (Railway provides this) |
| `CLERK_PUBLISHABLE_KEY` | Clerk frontend key |
| `CLERK_SECRET_KEY` | Clerk backend key |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account ID for R2 |
| `R2_ACCESS_KEY_ID` | R2 access key |
| `R2_SECRET_ACCESS_KEY` | R2 secret key |
| `R2_BUCKET_NAME` | R2 bucket name |
| `R2_PUBLIC_URL` | Public URL for R2 bucket |
| `PORT` | Server port (default: 3000) |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins |

## API Endpoints

### Health
- `GET /api/health` - Health check
- `GET /api/health/ready` - Readiness check

### Authentication
- `POST /api/users/sync` - Sync Clerk user to database

### Users
- `GET /api/users/me` - Get current user
- `PUT /api/users/me` - Update profile
- `GET /api/users/:id` - Get user by ID
- `GET /api/users/search` - Search users
- `POST /api/users/:id/follow` - Follow user
- `DELETE /api/users/:id/follow` - Unfollow user
- `GET /api/users/me/followers` - Get followers
- `GET /api/users/me/following` - Get following
- `GET /api/users/me/buddies` - Get buddies
- `DELETE /api/users/me/buddies/:id` - Remove buddy
- `POST /api/users/:id/buddy-request` - Send buddy request
- `GET /api/users/:userId/toolboxes` - Get user's toolboxes

### Buddy Requests
- `GET /api/buddy-requests` - Get buddy requests
- `PUT /api/buddy-requests/:id` - Respond to request

### Toolboxes
- `GET /api/toolboxes` - List toolboxes
- `POST /api/toolboxes` - Create toolbox
- `GET /api/toolboxes/:id` - Get toolbox
- `PUT /api/toolboxes/:id` - Update toolbox
- `DELETE /api/toolboxes/:id` - Delete toolbox
- `GET /api/toolboxes/:id/tools` - List tools in toolbox
- `POST /api/toolboxes/:id/tools` - Create tool
- `GET /api/toolboxes/:id/permissions` - Get permissions
- `POST /api/toolboxes/:id/permissions` - Add permission
- `DELETE /api/toolboxes/:id/permissions/:userId` - Remove permission

### Tools
- `GET /api/tools/:id` - Get tool
- `PUT /api/tools/:id` - Update tool
- `DELETE /api/tools/:id` - Delete tool
- `POST /api/tools/:id/images/upload-url` - Get upload URL
- `POST /api/tools/:id/images` - Add image
- `DELETE /api/tools/:id/images/:imageId` - Delete image
- `GET /api/tools/shared` - Get lent out tools
- `GET /api/tools/borrowed` - Get borrowed tools

### Trackers
- `GET /api/trackers` - List trackers
- `GET /api/trackers/tools/:id/location` - Get tool location
- `POST /api/trackers/tools/:id/tracker` - Add tracker
- `PUT /api/trackers/tools/:id/tracker` - Update location
- `DELETE /api/trackers/tools/:id/tracker` - Remove tracker
- `GET /api/trackers/tools/:id/location/history` - Location history

### Lending
- `POST /api/lending/tools/:id/lend-request` - Request to borrow
- `GET /api/lending/incoming` - Incoming requests
- `GET /api/lending/outgoing` - Outgoing requests
- `PUT /api/lending/:id/respond` - Respond to request
- `POST /api/lending/:id/return` - Return tool
- `GET /api/lending/history` - Lending history

## Railway Deployment

### Prerequisites

1. **Railway Account**: Sign up at [railway.app](https://railway.app) (GitHub login recommended)
2. **Clerk Account**: Sign up at [clerk.com](https://clerk.com)
3. **Cloudflare R2**: Sign up at [cloudflare.com](https://cloudflare.com) and create an R2 bucket

### Step 1: Install Railway CLI

```bash
npm install -g @railway/cli
```

### Step 2: Get Your API Token

1. Go to [railway.app](https://railway.app) → Login
2. Click profile icon (bottom left) → Account Settings → Tokens
3. Click "Create Token" → Name it "ToolKUDU CLI"
4. Copy the token

### Step 3: Deploy via CLI

```bash
# Navigate to railway folder
cd backend/railway

# Login with token
railway login --token YOUR_RAILWAY_TOKEN

# Create new project
railway init --name toolkudu-api

# Add PostgreSQL (DATABASE_URL is auto-set)
railway add --plugin postgresql

# Set environment variables
railway variables set CLERK_PUBLISHABLE_KEY=pk_test_xxx
railway variables set CLERK_SECRET_KEY=sk_test_xxx
railway variables set CLOUDFLARE_ACCOUNT_ID=xxx
railway variables set R2_ACCESS_KEY_ID=xxx
railway variables set R2_SECRET_ACCESS_KEY=xxx
railway variables set R2_BUCKET_NAME=toolkudu-images
railway variables set R2_PUBLIC_URL=https://pub-xxx.r2.dev
railway variables set NODE_ENV=production
railway variables set ALLOWED_ORIGINS=*

# Deploy
railway up

# Get your deployment URL
railway domain
```

### Step 4: Run Database Migrations

```bash
# Run migrations on Railway
railway run npm run db:migrate
```

### Step 5: Verify Deployment

```bash
curl https://YOUR-APP.railway.app/api/health
```

Expected response:
```json
{"status":"healthy","database":"connected","timestamp":"..."}
```

### Alternative: GitHub Deployment

1. Push code to GitHub
2. In Railway dashboard: New Project → Deploy from GitHub repo
3. Set root directory to `backend/railway`
4. Add PostgreSQL plugin
5. Set environment variables in Railway dashboard
6. Railway auto-deploys on push

### Credentials Checklist

| Service | What You Need | Where to Get It |
|---------|---------------|-----------------|
| Railway | API Token | railway.app → Account Settings → Tokens |
| Clerk | Publishable Key | clerk.com → API Keys |
| Clerk | Secret Key | clerk.com → API Keys |
| Cloudflare | Account ID | Dashboard URL or Overview page |
| Cloudflare R2 | Access Key ID | R2 → Manage API Tokens |
| Cloudflare R2 | Secret Access Key | R2 → Token creation |
| Cloudflare R2 | Bucket Name | Create in R2 dashboard |

## Architecture

```
src/
├── index.ts              # Express app entry
├── db/
│   └── index.ts          # Database connection & helpers
├── middleware/
│   ├── auth.ts           # Clerk authentication
│   └── errorHandler.ts   # Error handling
├── models/
│   └── types.ts          # TypeScript types
├── routes/
│   ├── health.ts         # Health checks
│   ├── toolboxes.ts      # Toolbox endpoints
│   ├── tools.ts          # Tool endpoints
│   ├── users.ts          # User endpoints
│   ├── buddies.ts        # Buddy request endpoints
│   ├── location.ts       # Tracker endpoints
│   └── sharing.ts        # Lending endpoints
├── services/
│   └── r2.ts             # Cloudflare R2 storage
└── utils/
    ├── pagination.ts     # Pagination helpers
    └── validation.ts     # Validation utilities
```
