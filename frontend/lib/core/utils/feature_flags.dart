/// Feature flags to control app functionality
/// These can be configured remotely in the future
class FeatureFlags {
  FeatureFlags._();

  /// GPS/Find Tool feature - currently disabled for web
  /// This feature requires native device capabilities
  static const bool enableFindTool = false;

  /// Buddies/Social features - enabled
  static const bool enableBuddies = true;

  /// Tool sharing/lending features - enabled
  static const bool enableSharing = true;

  /// Search for users - enabled
  static const bool enableUserSearch = true;

  /// Check if a feature is enabled
  static bool isEnabled(Feature feature) {
    switch (feature) {
      case Feature.findTool:
        return enableFindTool;
      case Feature.buddies:
        return enableBuddies;
      case Feature.sharing:
        return enableSharing;
      case Feature.userSearch:
        return enableUserSearch;
    }
  }
}

/// Available features that can be toggled
enum Feature {
  findTool,
  buddies,
  sharing,
  userSearch,
}
