# ToolKUDU - Project Notes for Claude

## Important Project Structure Notes

### UIReference Folder
**DO NOT MODIFY** the `UIReference/` folder. This folder contains reference UI code for styling inspiration only. It is NOT part of the actual application.

### Actual Project Structure
- `frontend/` - The actual frontend application code
- `backend/` - The actual backend application code
- `docs/` - Documentation

## Color Palette (User Preference)

### Light Theme
- Primary: Sage green (#6B8E7B)
- Accent: Terracotta (#C77B58)
- Background: Warm white (#FAFAF8)
- Text: Charcoal (#2D3436)

### Dark Theme - "Garage Night" (GitHub-inspired)
- Primary: Slate Gray (#5D6D7E)
- Accent: Safety Orange (#E67E22)
- Background: Deep dark (#0D1117)
- Surface: Elevated surface (#161B22)
- Surface Elevated: Cards/dialogs (#21262D)
- Border: Subtle border (#30363D)
- Text Primary: Bright white (#F0F6FC)
- Text Secondary: Muted gray (#8B949E)
- Success: GitHub green (#3FB950)
- Warning: GitHub orange (#F0883E)

## Feature Flags
Located in `frontend/lib/core/utils/feature_flags.dart`:
- `enableFindTool`: **DISABLED** - GPS/Find Tool feature hidden for web
- `enableBuddies`: Enabled - Social features
- `enableSharing`: Enabled - Tool sharing/lending
- `enableUserSearch`: Enabled - Search for users

## Navigation Structure

### Mobile/Tablet Layout
- **Bottom Nav Tabs**: Home, Search, Buddies, Share
- **Account Icon** (top-right): Opens sliding drawer from right
- **Account Drawer** (`frontend/lib/shared/widgets/account_drawer.dart`):
  - User avatar + name
  - View Profile → `/profile`
  - Edit Profile → `/profile/edit`
  - Settings → `/profile/settings`
  - Sign Out

### Desktop Layout (>=900px)
- **Top Header**: Logo, Home, Search, Buddies, Share nav links
- **Account Dropdown** (right): View Profile, Edit Profile, Settings

### Deep Links
- `/u/:username` - Profile sharing link (e.g., `https://toolkudu.app/u/johndoe`)

## Responsive Layout
Located in `frontend/lib/core/utils/responsive.dart`:
- **Mobile** (<600px): Bottom navigation with 4 tabs + account icon
- **Tablet** (600-899px): Bottom navigation + account icon
- **Desktop** (>=900px): Top header navigation with logo, nav links, account dropdown

## Terminology
- Use **"Tool Buddies"** instead of "Followers/Following"
- Button labels: "Add as Tool Buddy", "My Buddies", "Accept/Decline"
- Stats: "Tool Buddies" count, "Toolboxes" count

## Funny Messages System
Located in `frontend/lib/core/utils/funny_messages.dart`:
- Dad joke style, industry-themed messages
- Categories: Success, Error, Loading, Empty States, Confirmations, Welcome
- Use `FunnySnackBar` widget for success/error notifications
- Use `FunnyMessages` class for empty states and dialogs

## Username System
- **Uniqueness**: Usernames must be unique (checked during registration)
- **Validation**: 3+ chars, alphanumeric + underscore only
- **Availability Check**: Debounced API call with checkmark/X indicator
- **Suggestions**: When taken, shows 3 alternatives (e.g., `john_1`, `john_tools`, `john_2024`)
- **Auto-generation**: Google/Magic Link users get username from email prefix
- **Change Cooldown**: Can edit username once per 30 days (Edit Profile screen)

## Buddy System
- **Borrow Button**: Shows on available tools when viewing a buddy's profile (not just in borrow mode)
- **Share Profile**: Button on profiles to copy/share profile link
- **Quick Request**: Share tab FAB offers "From My Buddies" or "Search for Someone"
- **Find Buddies**: Uses `/buddies/find` route (GoRouter) - opens user search dialog

## Search Tab (Tool Discovery)
The Search tab is for **location-based tool discovery**, not user search.
- **Purpose**: Find tools available for borrowing within 100 miles
- **User Search**: Moved to Buddies tab → "Find Buddies" button → `/buddies/find`
- **Files**:
  - `frontend/lib/features/search/screens/search_screen.dart` - Tool search screen
  - `frontend/lib/features/search/widgets/tool_search_card.dart` - Tool result card with buddy highlight
  - `frontend/lib/features/search/widgets/user_search_dialog.dart` - User search (accessed from Buddies tab)
  - `frontend/lib/core/services/tool_search_service.dart` - Tool search API service
  - `frontend/lib/core/providers/tool_search_provider.dart` - Tool search state management
  - `frontend/lib/core/models/tool_search_result.dart` - Tool search result model
- **Features**:
  - Location indicator showing search area (zipcode)
  - Category filter chips
  - Buddy tools highlighted with accent border + "Buddy" chip
  - Section headers: "From Your Buddies" and "Nearby Tools"
  - Pagination with infinite scroll

## Location Permission Flow
- **When**: Popup dialog shown after successful login (Google Sign-In, Magic Link, or regular login)
- **Trigger**: Only shown if user hasn't set location and hasn't been prompted before
- **Dialog Options**:
  1. "Use My Location" → Triggers native OS permission dialog (GPS)
  2. "Enter Zipcode Instead" → Manual 5-digit zipcode entry with geocoding
  3. "Skip for Now" → Dismisses dialog, marks as prompted (won't show again)
- **Files**:
  - `frontend/lib/shared/widgets/location_permission_dialog.dart` - The popup dialog
  - `frontend/lib/core/services/location_service.dart` - GPS and geocoding service
  - `frontend/lib/core/providers/location_provider.dart` - Location state management
- **User Model**: Includes `latitude`, `longitude`, `zipcode`, `locationSource` fields
- **Privacy**: Location is only used for finding nearby tools, never shared publicly

## UI Components
- **Glassmorphism**: Subtle blur effects on nav bars and optionally on cards (`enableGlass: true`)
- **Desktop Header**: `frontend/lib/app/desktop_header.dart` - Top nav for web
- **Account Drawer**: `frontend/lib/shared/widgets/account_drawer.dart` - Sliding drawer for mobile
- **Responsive Container**: Wraps content with max-width constraints for desktop
- **Location Permission Dialog**: `frontend/lib/shared/widgets/location_permission_dialog.dart` - Post-login location request
