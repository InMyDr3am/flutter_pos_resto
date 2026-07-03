import 'order.dart';
import 'order_item.dart';
import 'payment.dart';

/// An order together with its line items (and payment, once paid). Used by
/// the kitchen, cashier, payment, and sales-report screens so they don't
/// each re-implement the same join.
class OrderDetail {
  const OrderDetail({required this.order, required this.items, this.payment});

  final Order order;
  final List<OrderItem> items;
  final Payment? payment;

  num get totalAmount => items.fold<num>(0, (sum, item) => sum + item.subtotal);

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['order_items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final paymentsJson = (json['payments'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return OrderDetail(
      order: Order.fromJson(json),
      items: itemsJson.map(OrderItem.fromJson).toList(),
      payment: paymentsJson.isNotEmpty ? Payment.fromJson(paymentsJson.first) : null,
    );
  }
}
