class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.stockQuantity,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String unit;
  final num stockQuantity;
  final DateTime createdAt;

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        stockQuantity: json['stock_quantity'] as num? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'stock_quantity': stockQuantity,
      };
}
