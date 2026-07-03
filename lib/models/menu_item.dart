class MenuItem {
  const MenuItem({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
  });

  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final num price;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Populated when the row is joined with `menu_categories`.
  final String? categoryName;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        categoryId: json['category_id'] as String?,
        name: json['name'] as String,
        description: json['description'] as String?,
        price: json['price'] as num,
        imageUrl: json['image_url'] as String?,
        isAvailable: json['is_available'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        categoryName: (json['menu_categories'] as Map<String, dynamic>?)?['name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'image_url': imageUrl,
        'is_available': isAvailable,
      };

  MenuItem copyWith({
    String? categoryId,
    String? name,
    String? description,
    num? price,
    String? imageUrl,
    bool? isAvailable,
  }) {
    return MenuItem(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      updatedAt: updatedAt,
      categoryName: categoryName,
    );
  }
}
