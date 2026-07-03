class PurchaseBatch {
  const PurchaseBatch({
    required this.id,
    required this.purchaseDate,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });

  final String id;
  final DateTime purchaseDate;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  factory PurchaseBatch.fromJson(Map<String, dynamic> json) => PurchaseBatch(
        id: json['id'] as String,
        purchaseDate: DateTime.parse(json['purchase_date'] as String),
        notes: json['notes'] as String?,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'purchase_date': purchaseDate.toIso8601String().split('T').first,
        'notes': notes,
      };
}
