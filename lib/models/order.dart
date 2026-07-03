class Order {
  const Order({
    required this.id,
    required this.tableNumber,
    required this.customerName,
    required this.orderDate,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tableNumber;
  final String customerName;
  final DateTime orderDate;
  final String status;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        tableNumber: json['table_number'] as String,
        customerName: json['customer_name'] as String,
        orderDate: DateTime.parse(json['order_date'] as String),
        status: json['status'] as String,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'table_number': tableNumber,
        'customer_name': customerName,
        'order_date': orderDate.toIso8601String().split('T').first,
        'status': status,
      };
}
