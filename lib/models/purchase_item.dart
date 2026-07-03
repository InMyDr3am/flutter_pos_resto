class PurchaseItem {
  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.ingredientId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    this.ingredientName,
    this.ingredientUnit,
  });

  final String id;
  final String purchaseId;
  final String ingredientId;
  final num quantity;
  final num unitPrice;
  final num totalPrice;
  final DateTime createdAt;

  /// Populated when the row is joined with `ingredients`.
  final String? ingredientName;
  final String? ingredientUnit;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    final ingredient = json['ingredients'] as Map<String, dynamic>?;
    return PurchaseItem(
      id: json['id'] as String,
      purchaseId: json['purchase_id'] as String,
      ingredientId: json['ingredient_id'] as String,
      quantity: json['quantity'] as num,
      unitPrice: json['unit_price'] as num,
      totalPrice: json['total_price'] as num,
      createdAt: DateTime.parse(json['created_at'] as String),
      ingredientName: ingredient?['name'] as String?,
      ingredientUnit: ingredient?['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson(String purchaseId) => {
        'purchase_id': purchaseId,
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };
}
