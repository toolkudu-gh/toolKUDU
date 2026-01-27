enum ToolboxVisibility { private, buddies, public }

class Toolbox {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final ToolboxVisibility visibility;
  final String? icon;
  final String? color;
  final int toolCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Toolbox({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.visibility = ToolboxVisibility.private,
    this.icon,
    this.color,
    this.toolCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Toolbox.fromJson(Map<String, dynamic> json) {
    return Toolbox(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      visibility: _parseVisibility(json['visibility'] as String?),
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      toolCount: json['toolCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'visibility': visibility.name,
      'icon': icon,
      'color': color,
      'toolCount': toolCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ToolboxVisibility _parseVisibility(String? value) {
    switch (value) {
      case 'buddies':
        return ToolboxVisibility.buddies;
      case 'public':
        return ToolboxVisibility.public;
      default:
        return ToolboxVisibility.private;
    }
  }

  Toolbox copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    ToolboxVisibility? visibility,
    String? icon,
    String? color,
    int? toolCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Toolbox(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      toolCount: toolCount ?? this.toolCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
