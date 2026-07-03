import 'expense_batch.dart';
import 'expense_item.dart';

/// An expense report together with all its line items.
class ExpenseDetail {
  const ExpenseDetail({required this.batch, required this.items});

  final ExpenseBatch batch;
  final List<ExpenseItem> items;

  num get totalAmount => items.fold<num>(0, (sum, item) => sum + item.amount);

  factory ExpenseDetail.fromJson(Map<String, dynamic> json) {
    final itemsJson =
        (json['expense_items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return ExpenseDetail(
      batch: ExpenseBatch.fromJson(json),
      items: itemsJson.map(ExpenseItem.fromJson).toList(),
    );
  }
}
