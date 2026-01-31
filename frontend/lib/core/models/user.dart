class User {
  final String id;
  final String username;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final bool? isFollowing;
  final bool? isBuddy;
  final DateTime? lastUsernameChange;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing,
    this.isBuddy,
    this.lastUsernameChange,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool?,
      isBuddy: json['isBuddy'] as bool?,
      lastUsernameChange: json['lastUsernameChange'] != null
          ? DateTime.parse(json['lastUsernameChange'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isFollowing': isFollowing,
      'isBuddy': isBuddy,
      'lastUsernameChange': lastUsernameChange?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
    bool? isBuddy,
    DateTime? lastUsernameChange,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isBuddy: isBuddy ?? this.isBuddy,
      lastUsernameChange: lastUsernameChange ?? this.lastUsernameChange,
    );
  }

  String get displayNameOrUsername => displayName ?? username;

  /// Check if username can be changed (30-day cooldown)
  bool get canChangeUsername {
    if (lastUsernameChange == null) return true;
    final daysSinceChange = DateTime.now().difference(lastUsernameChange!).inDays;
    return daysSinceChange >= 30;
  }

  /// Get the date when username can be changed again
  DateTime? get usernameChangeAvailableDate {
    if (lastUsernameChange == null) return null;
    return lastUsernameChange!.add(const Duration(days: 30));
  }
}
