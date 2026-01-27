# ToolKUDU - Session Progress Summary

## Last Updated: January 25, 2026 (Session 2)

---

## Project Overview

**ToolKUDU** is a Flutter-based mobile/web application for organizing, sharing, and tracking tools with GPS integration. Users can:
- Create and organize tools in virtual toolboxes
- Share tools with buddies with granular permissions
- Borrow and lend tools through a request system
- Track tool locations using GPS, AirTags, and other tracking devices

---

## Current Status

### Backend Services (100% Complete)

All backend services are fully implemented:

1. **User Service** (`backend/services/user-service/`)
   - Profile CRUD, user search, follow/unfollow, buddy requests

2. **Tool Service** (`backend/services/tool-service/`)
   - Toolbox CRUD, Tool CRUD, S3 image uploads

3. **Sharing Service** (`backend/services/sharing-service/`)
   - Toolbox permissions, lending request flow, return functionality

4. **Location Service** (`backend/services/location-service/`)
   - GPS trackers (AirTag, Tile, cellular/satellite), location history

5. **Shared Package** (`backend/shared/`)
   - Database client, Cognito auth middleware, utilities

6. **Infrastructure** (`backend/infrastructure/serverless.yml`)
   - Cognito, S3, RDS PostgreSQL, SNS for notifications

---

### Frontend (Flutter) - Substantially Complete

#### Implemented Screens:
- **Auth**: Login, Register, Email Verification (with Google Sign-In & Magic Links)
- **Home**: Toolbox list, Toolbox detail, Tool detail, Add toolbox, Add tool
- **Search**: User search, User profile view
- **Share**: Lending/sharing management
- **Find My Tool**: GPS tracking view, Add tracker
- **Profile**: Profile view, Edit profile, Buddies list, Settings

#### Authentication Status:
- **Google Sign-In**: WORKING (People API enabled)
- **Email/Password**: Working (Cognito integration)
- **Magic Links**: Working

---

## Session Completed (January 25, 2026) - Buddy Terminology

### Friends → Buddy Terminology Change - COMPLETE

Reviewed permissions architecture and renamed "Friends" concept to "Buddy" throughout the entire codebase.

**Permissions Architecture Confirmed:**
| User Relationship | Public Toolboxes | Buddies Toolboxes | Private Toolboxes |
|-------------------|------------------|-------------------|-------------------|
| **Buddies** | Can view | Can view | Cannot view |
| **Followers** | Can view | Cannot view | Cannot view |
| **Non-followers** | Can view | Cannot view | Cannot view |

**Database Schema Changes** (`backend/shared/db/schema.sql`):
- `friend_requests` table → `buddy_requests`
- `friendships` table → `buddies`
- `visibility_type` enum: `'friends'` → `'buddies'`
- Notification types: `friend_request` → `buddy_request`, `friend_accepted` → `buddy_accepted`
- Trigger: `create_friendship_on_accept()` → `create_buddy_on_accept()`

**Backend User Service Changes** (`backend/services/user-service/`):
- `sendFriendRequest()` → `sendBuddyRequest()`
- `respondToFriendRequest()` → `respondToBuddyRequest()`
- `getFriendRequests()` → `getBuddyRequests()`
- `getFriends()` → `getBuddies()`
- `removeFriend()` → `removeBuddy()`
- API endpoints: `/friend-request` → `/buddy-request`, `/friends` → `/buddies`
- Model interfaces: `FriendRequest` → `BuddyRequest`, `Friendship` → `Buddy`

**Backend Tool/Sharing Service Changes**:
- `VisibilityType`: `'friends'` → `'buddies'`
- All friendship table references → buddies table

**Frontend Model Changes**:
- `User.isFriend` → `User.isBuddy`
- `ToolboxVisibility.friends` → `ToolboxVisibility.buddies`

**Frontend UI Changes**:
- "Add Friend" → "Be my Buddy"
- "Friends" → "Buddies"
- "Remove Friend" → "Remove Buddy"
- Created `buddies_screen.dart` (replaced `friends_screen.dart`)
- Route: `/profile/friends` → `/profile/buddies`
- Followers tab now shows "Add Buddy" button option

---

## Session Completed (January 25, 2026) - Borrow Feature

### Borrow Request Feature - COMPLETE

Implemented the full borrow request flow allowing users to request tools from other users:

**New Files Created:**
1. `frontend/lib/core/models/lending_request.dart` - Models for LendingRequest, BorrowedTool, LentOutTool
2. `frontend/lib/core/providers/lending_provider.dart` - State management for lending operations
3. `frontend/lib/features/share/widgets/borrow_request_dialog.dart` - Dialog for submitting borrow requests

**Files Modified:**
1. `frontend/lib/features/share/screens/share_screen.dart`:
   - Added FAB button "Request to Borrow"
   - Displays incoming requests (approve/decline buttons)
   - Displays outgoing pending requests
   - Shows "Lent Out" tools with borrower info
   - Shows "Borrowed" tools with return button

2. `frontend/lib/features/search/screens/search_screen.dart`:
   - Added `borrowMode` parameter
   - Shows info banner in borrow mode
   - Different navigation flow for borrow mode

3. `frontend/lib/features/search/screens/user_profile_screen.dart`:
   - Added `borrowMode` parameter
   - Shows user's public toolboxes with expandable tiles
   - Lists tools inside each toolbox
   - Shows availability status (Available/Not Available)
   - "Borrow" button on available tools opens request dialog

4. `frontend/lib/app/router.dart`:
   - Updated search route to handle `?mode=borrow` query parameter
   - Updated user-profile route to pass borrowMode to screen

**User Flow:**
1. User taps "Request to Borrow" FAB on Share tab
2. Navigates to Search screen in borrow mode
3. User searches and selects a user
4. Views user's toolboxes and expands to see tools
5. Taps "Borrow" on an available tool
6. Dialog appears to add optional message
7. Request is sent and user returns to Share tab
8. Pending requests appear in the Requests tab

---

## Session Completed (January 22, 2026)

### Magic Link Authentication:
1. Created dedicated Magic Link screen (`frontend/lib/features/auth/screens/magic_link_screen.dart`)
2. Added `/magic-link` route to router
3. **Auto-registration**: Magic link now auto-registers new users on verification
4. Fixed router rebuild issue (was causing navigation back to login on state changes)
5. User identity maintained via email across all auth methods

### Router Fix:
- Created `AuthChangeNotifier` class to only refresh router when `isAuthenticated` changes
- Prevents router from rebuilding on every `isLoading` state toggle

### Chrome Logo:
- Downloaded high-res Chrome logo to `assets/images/chrome_logo.png`
- Using local asset instead of network URL (avoids CORS issues)

---

## Session Completed (January 21, 2026)

### Theme/Color Updates Applied:

1. **New Color Scheme** (`frontend/lib/shared/theme/app_theme.dart`):
   - Background: `#EBFFE6` (light mint green)
   - Text color: `#802E20` (reddish brown)
   - Highlights/Headings: `#94FF77` (bright green)

2. **Login Screen Updates** (`frontend/lib/features/auth/screens/login_screen.dart`):
   - Google Auth button: Chrome logo (local asset) + highlight green text/border
   - Magic Link button: Highlight green text/border
   - App title "ToolKUDU": Highlight green color
   - Chrome logo stored at: `assets/images/chrome_logo.png` (high-res from Wikipedia)

---

## Key Technical Notes

### Theme-Level Button Styling (Recommended)
OutlinedButton text/border colors are controlled via `outlinedButtonTheme` in `app_theme.dart`:
```dart
outlinedButtonTheme: OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    foregroundColor: primaryColor, // Controls text & icon color
    side: const BorderSide(color: primaryColor), // Controls border
  ),
),
```
Then use simple `OutlinedButton.icon` without explicit colors - theme handles it.

### Google Sign-In Configuration
- Client ID configured in `frontend/lib/core/config/cognito_config.dart`
- Uses `google_sign_in` package with scopes: `['email', 'profile']`
- People API must be enabled in Google Cloud Console

---

## What Remains

### Backend (Minor):
- [ ] Notification Service (push notifications via SNS)

### Frontend - Borrow Request Feature:
- [x] ~~COMPLETE~~ (January 25, 2026)

### Frontend - Other:
- [ ] Connect screens to real backend API (currently using mock data in dev mode)
- [ ] Remove test/mock data from screens (Search has hardcoded users)
- [ ] Deploy and test with production Cognito/AWS services
- [ ] Notifications UI
- [ ] Real-time location tracking visualization

### Deployment:
- [ ] Deploy backend to AWS
- [ ] Configure production environment variables
- [ ] App store preparation (iOS/Android)

---

## Project Structure

```
toolKUDU/
├── backend/
│   ├── services/
│   │   ├── user-service/        ✅ Complete
│   │   ├── tool-service/        ✅ Complete
│   │   ├── sharing-service/     ✅ Complete
│   │   ├── location-service/    ✅ Complete
│   │   └── notification-service/ ⏳ Pending
│   ├── shared/                  ✅ Complete
│   └── infrastructure/          ✅ Complete
├── frontend/                    ✅ UI Complete (needs API integration)
│   └── lib/
│       ├── app/                 (router)
│       ├── core/                (services, providers, models, config)
│       ├── features/            (auth, home, search, share, find_tool, profile)
│       └── shared/              (theme, widgets)
└── docs/
```

---

## Tech Stack

- **Frontend**: Flutter 3.10+ (iOS, Android, Web)
- **State Management**: Riverpod
- **Navigation**: go_router
- **Backend**: Node.js/TypeScript on AWS Lambda
- **Database**: AWS RDS PostgreSQL
- **Auth**: AWS Cognito + Google Sign-In
- **Storage**: AWS S3
- **IaC**: Serverless Framework

---

## To Resume Next Session

Run the Flutter app:
```bash
cd frontend
flutter run -d chrome
```

Or continue with specific tasks:
```
claude "Continue ToolKUDU - connect frontend to backend API"
claude "Continue ToolKUDU - implement notification service"
claude "Continue ToolKUDU - deploy backend to AWS"
```

---

## Important File Locations

| Purpose | Path |
|---------|------|
| Theme/Colors | `frontend/lib/shared/theme/app_theme.dart` |
| Login Screen | `frontend/lib/features/auth/screens/login_screen.dart` |
| Auth Service | `frontend/lib/core/services/auth_service.dart` |
| Auth Provider | `frontend/lib/core/providers/auth_provider.dart` |
| Lending Provider | `frontend/lib/core/providers/lending_provider.dart` |
| LendingRequest Model | `frontend/lib/core/models/lending_request.dart` |
| Share Screen | `frontend/lib/features/share/screens/share_screen.dart` |
| Borrow Dialog | `frontend/lib/features/share/widgets/borrow_request_dialog.dart` |
| Buddies Screen | `frontend/lib/features/profile/screens/buddies_screen.dart` |
| Cognito Config | `frontend/lib/core/config/cognito_config.dart` |
| API Service | `frontend/lib/core/services/api_service.dart` |
| Router | `frontend/lib/app/router.dart` |
| Database Schema | `backend/shared/db/schema.sql` |
| Infrastructure | `backend/infrastructure/serverless.yml` |
