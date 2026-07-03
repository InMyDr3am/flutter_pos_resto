class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.totalAmount,
    this.amountGiven,
    this.changeAmount,
    this.processedBy,
    required this.paidAt,
  });

  final String id;
  final String orderId;
  final String paymentMethod;
  final num totalAmount;
  final num? amountGiven;
  final num? changeAmount;
  final String? processedBy;
  final DateTime paidAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        paymentMethod: json['payment_method'] as String,
        totalAmount: json['total_amount'] as num,
        amountGiven: json['amount_given'] as num?,
        changeAmount: json['change_amount'] as num?,
        processedBy: json['processed_by'] as String?,
        paidAt: DateTime.parse(json['paid_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'payment_method': paymentMethod,
        'total_amount': totalAmount,
        'amount_given': amountGiven,
        'change_amount': changeAmount,
      };
}
