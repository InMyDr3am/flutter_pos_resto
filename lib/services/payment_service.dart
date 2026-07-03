import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/payment.dart';
import 'supabase_client.dart';

class PaymentService {
  final SupabaseClient _db = AppSupabase.client;

  Future<Payment> payOrder({
    required String orderId,
    required String method,
    required num totalAmount,
    num? amountGiven,
    required String processedBy,
  }) async {
    final isCash = method == PaymentMethod.cash;
    final changeAmount = isCash && amountGiven != null ? amountGiven - totalAmount : null;

    final row = await _db
        .from(SupaTables.payments)
        .insert({
          'order_id': orderId,
          'payment_method': method,
          'total_amount': totalAmount,
          'amount_given': isCash ? amountGiven : null,
          'change_amount': isCash ? changeAmount : null,
          'processed_by': processedBy,
        })
        .select()
        .single();

    await _db.from(SupaTables.orders).update({
      'status': OrderStatus.paid,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    return Payment.fromJson(row);
  }
}
