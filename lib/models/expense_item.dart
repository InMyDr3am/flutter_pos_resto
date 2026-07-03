class ExpenseItem {
  const ExpenseItem({
    required this.id,
    required this.expenseId,
    required this.category,
    this.description,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String expenseId;
  final String category;
  final String? description;
  final num amount;
  final DateTime createdAt;

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
        id: json['id'] as String,
        expenseId: json['expense_id'] as String,
        category: json['category'] as String,
        description: json['description'] as String?,
        amount: json['amount'] as num,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson(String expenseId) => {
        'expense_id': expenseId,
        'category': category,
        'description': description,
        'amount': amount,
      };
}
