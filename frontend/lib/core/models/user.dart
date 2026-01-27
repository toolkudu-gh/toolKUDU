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
    );
  }

  String get displayNameOrUsername => displayName ?? username;
}
