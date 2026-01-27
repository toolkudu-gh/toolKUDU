class Tool {
  final String id;
  final String toolboxId;
  final String name;
  final String? description;
  final String? category;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final String? notes;
  final bool isAvailable;
  final List<ToolImage> images;
  final bool hasTracker;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tool({
    required this.id,
    required this.toolboxId,
    required this.name,
    this.description,
    this.category,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.purchasePrice,
    this.notes,
    this.isAvailable = true,
    this.images = const [],
    this.hasTracker = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      id: json['id'] as String,
      toolboxId: json['toolboxId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serialNumber'] as String?,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => ToolImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hasTracker: json['hasTracker'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toolboxId': toolboxId,
      'name': name,
      'description': description,
      'category': category,
      'brand': brand,
      'model': model,
      'serialNumber': serialNumber,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'purchasePrice': purchasePrice,
      'notes': notes,
      'isAvailable': isAvailable,
      'images': images.map((e) => e.toJson()).toList(),
      'hasTracker': hasTracker,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String? get primaryImageUrl => images.isNotEmpty ? images.first.url : null;

  Tool copyWith({
    String? id,
    String? toolboxId,
    String? name,
    String? description,
    String? category,
    String? brand,
    String? model,
    String? serialNumber,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? notes,
    bool? isAvailable,
    List<ToolImage>? images,
    bool? hasTracker,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tool(
      id: id ?? this.id,
      toolboxId: toolboxId ?? this.toolboxId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      notes: notes ?? this.notes,
      isAvailable: isAvailable ?? this.isAvailable,
      images: images ?? this.images,
      hasTracker: hasTracker ?? this.hasTracker,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ToolImage {
  final String id;
  final String url;
  final int orderIndex;

  const ToolImage({
    required this.id,
    required this.url,
    required this.orderIndex,
  });

  factory ToolImage.fromJson(Map<String, dynamic> json) {
    return ToolImage(
      id: json['id'] as String,
      url: json['url'] as String,
      orderIndex: json['orderIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'orderIndex': orderIndex,
    };
  }
}
