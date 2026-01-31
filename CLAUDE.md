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

## Responsive Layout
Located in `frontend/lib/core/utils/responsive.dart`:
- **Mobile** (<600px): Bottom navigation with 4 tabs
- **Tablet** (600-899px): Bottom navigation
- **Desktop** (>=900px): Top header navigation with logo, nav links, user dropdown

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

## UI Components
- **Glassmorphism**: Subtle blur effects on nav bars and optionally on cards (`enableGlass: true`)
- **Desktop Header**: `frontend/lib/app/desktop_header.dart` - Top nav for web
- **Responsive Container**: Wraps content with max-width constraints for desktop
