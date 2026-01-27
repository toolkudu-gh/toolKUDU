enum LendingStatus { pending, approved, denied, active, returned, cancelled }

class LendingRequest {
  final String id;
  final LendingTool tool;
  final LendingUser requester;
  final LendingUser owner;
  final LendingStatus status;
  final String? message;
  final String? responseMessage;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  const LendingRequest({
    required this.id,
    required this.tool,
    required this.requester,
    required this.owner,
    required this.status,
    this.message,
    this.responseMessage,
    required this.requestedAt,
    this.respondedAt,
  });

  factory LendingRequest.fromJson(Map<String, dynamic> json) {
    return LendingRequest(
      id: json['id'] as String,
      tool: LendingTool.fromJson(json['tool'] as Map<String, dynamic>),
      requester: LendingUser.fromJson(json['requester'] as Map<String, dynamic>),
      owner: LendingUser.fromJson(json['owner'] as Map<String, dynamic>),
      status: _parseStatus(json['status'] as String),
      message: json['message'] as String?,
      responseMessage: json['responseMessage'] as String?,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
    );
  }

  static LendingStatus _parseStatus(String value) {
    switch (value) {
      case 'pending':
        return LendingStatus.pending;
      case 'approved':
        return LendingStatus.approved;
      case 'denied':
        return LendingStatus.denied;
      case 'active':
        return LendingStatus.active;
      case 'returned':
        return LendingStatus.returned;
      case 'cancelled':
        return LendingStatus.cancelled;
      default:
        return LendingStatus.pending;
    }
  }

  bool get isPending => status == LendingStatus.pending;
  bool get isActive => status == LendingStatus.active;
  bool get isDenied => status == LendingStatus.denied;
  bool get isReturned => status == LendingStatus.returned;
}

class LendingTool {
  final String id;
  final String name;
  final String? description;

  const LendingTool({
    required this.id,
    required this.name,
    this.description,
  });

  factory LendingTool.fromJson(Map<String, dynamic> json) {
    return LendingTool(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class LendingUser {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const LendingUser({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory LendingUser.fromJson(Map<String, dynamic> json) {
    return LendingUser(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  String get displayNameOrUsername => displayName ?? username;
}

class BorrowedTool {
  final String id;
  final String name;
  final String? description;
  final String ownerUsername;
  final DateTime borrowedAt;
  final String lendingRequestId;

  const BorrowedTool({
    required this.id,
    required this.name,
    this.description,
    required this.ownerUsername,
    required this.borrowedAt,
    required this.lendingRequestId,
  });

  factory BorrowedTool.fromJson(Map<String, dynamic> json) {
    return BorrowedTool(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerUsername: json['ownerUsername'] as String,
      borrowedAt: DateTime.parse(json['borrowedAt'] as String),
      lendingRequestId: json['lendingRequestId'] as String,
    );
  }
}

class LentOutTool {
  final String id;
  final String name;
  final String? description;
  final String borrowerUsername;
  final DateTime borrowedAt;

  const LentOutTool({
    required this.id,
    required this.name,
    this.description,
    required this.borrowerUsername,
    required this.borrowedAt,
  });

  factory LentOutTool.fromJson(Map<String, dynamic> json) {
    return LentOutTool(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      borrowerUsername: json['borrowerUsername'] as String,
      borrowedAt: DateTime.parse(json['borrowedAt'] as String),
    );
  }
}
