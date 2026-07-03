class ExpenseBatch {
  const ExpenseBatch({
    required this.id,
    required this.expenseDate,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final DateTime expenseDate;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  factory ExpenseBatch.fromJson(Map<String, dynamic> json) => ExpenseBatch(
        id: json['id'] as String,
        expenseDate: DateTime.parse(json['expense_date'] as String),
        notes: json['notes'] as String?,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'expense_date': expenseDate.toIso8601String().split('T').first,
        'notes': notes,
      };
}
