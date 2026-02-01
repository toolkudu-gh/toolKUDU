/// Model for tool search results from location-based search
class ToolSearchResult {
  final String toolId;
  final String toolName;
  final String? description;
  final String? category;
  final String? brand;
  final String? model;
  final String? primaryImageUrl;
  final String toolboxId;
  final String toolboxName;
  final String ownerId;
  final String ownerUsername;
  final String? ownerDisplayName;
  final String? ownerAvatarUrl;
  final double distanceMiles;
  final bool isBuddy;
  final bool isAvailable;

  const ToolSearchResult({
    required this.toolId,
    required this.toolName,
    this.description,
    this.category,
    this.brand,
    this.model,
    this.primaryImageUrl,
    required this.toolboxId,
    required this.toolboxName,
    required this.ownerId,
    required this.ownerUsername,
    this.ownerDisplayName,
    this.ownerAvatarUrl,
    required this.distanceMiles,
    this.isBuddy = false,
    this.isAvailable = true,
  });

  factory ToolSearchResult.fromJson(Map<String, dynamic> json) {
    return ToolSearchResult(
      toolId: json['toolId'] as String,
      toolName: json['toolName'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      primaryImageUrl: json['primaryImageUrl'] as String?,
      toolboxId: json['toolboxId'] as String,
      toolboxName: json['toolboxName'] as String,
      ownerId: json['ownerId'] as String,
      ownerUsername: json['ownerUsername'] as String,
      ownerDisplayName: json['ownerDisplayName'] as String?,
      ownerAvatarUrl: json['ownerAvatarUrl'] as String?,
      distanceMiles: (json['distanceMiles'] as num).toDouble(),
      isBuddy: json['isBuddy'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toolId': toolId,
      'toolName': toolName,
      'description': description,
      'category': category,
      'brand': brand,
      'model': model,
      'primaryImageUrl': primaryImageUrl,
      'toolboxId': toolboxId,
      'toolboxName': toolboxName,
      'ownerId': ownerId,
      'ownerUsername': ownerUsername,
      'ownerDisplayName': ownerDisplayName,
      'ownerAvatarUrl': ownerAvatarUrl,
      'distanceMiles': distanceMiles,
      'isBuddy': isBuddy,
      'isAvailable': isAvailable,
    };
  }

  /// Get owner display name or fallback to username
  String get ownerDisplayNameOrUsername => ownerDisplayName ?? ownerUsername;

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceMiles < 1) {
      return '< 1 mi';
    } else if (distanceMiles < 10) {
      return '${distanceMiles.toStringAsFixed(1)} mi';
    } else {
      return '${distanceMiles.round()} mi';
    }
  }

  /// Get brand and model combined string
  String? get brandAndModel {
    if (brand != null && model != null) {
      return '$brand $model';
    }
    return brand ?? model;
  }

  ToolSearchResult copyWith({
    String? toolId,
    String? toolName,
    String? description,
    String? category,
    String? brand,
    String? model,
    String? primaryImageUrl,
    String? toolboxId,
    String? toolboxName,
    String? ownerId,
    String? ownerUsername,
    String? ownerDisplayName,
    String? ownerAvatarUrl,
    double? distanceMiles,
    bool? isBuddy,
    bool? isAvailable,
  }) {
    return ToolSearchResult(
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      primaryImageUrl: primaryImageUrl ?? this.primaryImageUrl,
      toolboxId: toolboxId ?? this.toolboxId,
      toolboxName: toolboxName ?? this.toolboxName,
      ownerId: ownerId ?? this.ownerId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerDisplayName: ownerDisplayName ?? this.ownerDisplayName,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      distanceMiles: distanceMiles ?? this.distanceMiles,
      isBuddy: isBuddy ?? this.isBuddy,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// Tool category for filtering
class ToolCategory {
  final String id;
  final String name;
  final String? icon;
  final int toolCount;

  const ToolCategory({
    required this.id,
    required this.name,
    this.icon,
    this.toolCount = 0,
  });

  factory ToolCategory.fromJson(Map<String, dynamic> json) {
    return ToolCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      toolCount: json['toolCount'] as int? ?? 0,
    );
  }
}
