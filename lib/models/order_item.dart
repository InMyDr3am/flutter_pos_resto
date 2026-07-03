class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    this.note,
    required this.priceAtOrder,
    required this.createdAt,
    this.menuItemName,
  });

  final String id;
  final String orderId;
  final String menuItemId;
  final int quantity;
  final String? note;
  final num priceAtOrder;
  final DateTime createdAt;

  /// Populated when the row is joined with `menu_items`.
  final String? menuItemName;

  num get subtotal => priceAtOrder * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        menuItemId: json['menu_item_id'] as String,
        quantity: json['quantity'] as int,
        note: json['note'] as String?,
        priceAtOrder: json['price_at_order'] as num,
        createdAt: DateTime.parse(json['created_at'] as String),
        menuItemName: (json['menu_items'] as Map<String, dynamic>?)?['name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'menu_item_id': menuItemId,
        'quantity': quantity,
        'note': note,
        'price_at_order': priceAtOrder,
      };
}
