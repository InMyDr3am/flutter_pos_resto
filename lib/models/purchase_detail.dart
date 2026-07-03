import 'purchase_batch.dart';
import 'purchase_item.dart';

/// A shopping trip together with all the ingredients bought on it.
class PurchaseDetail {
  const PurchaseDetail({required this.batch, required this.items});

  final PurchaseBatch batch;
  final List<PurchaseItem> items;

  num get totalAmount => items.fold<num>(0, (sum, item) => sum + item.totalPrice);

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['ingredient_purchase_items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return PurchaseDetail(
      batch: PurchaseBatch.fromJson(json),
      items: itemsJson.map(PurchaseItem.fromJson).toList(),
    );
  }
}
