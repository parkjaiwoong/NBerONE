class ShopModel {
  final String id;
  final String name;
  final String url;
  final String? appUrl;
  final String category; // New category field
  final int colorValue;
  final bool isCustom;

  ShopModel({
    required this.id,
    required this.name,
    required this.url,
    this.appUrl,
    this.category = '기타', // Default category
    required this.colorValue,
    this.isCustom = false,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'appUrl': appUrl,
      'category': category,
      'colorValue': colorValue,
      'isCustom': isCustom,
    };
  }

  // Create from JSON
  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      appUrl: json['appUrl'] as String?,
      category: json['category'] as String? ?? '기타',
      colorValue: json['colorValue'] as int,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  ShopModel copyWith({
    String? id,
    String? name,
    String? url,
    String? appUrl,
    String? category,
    int? colorValue,
    bool? isCustom,
  }) {
    return ShopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      appUrl: appUrl ?? this.appUrl,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}
