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

1. Create a new project on Railway
2. Add PostgreSQL database
3. Connect this repository
4. Set root directory to `backend/railway`
5. Add environment variables
6. Deploy!

Railway auto-detects the Dockerfile and deploys accordingly.

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
