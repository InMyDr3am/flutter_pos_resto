import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import 'service_providers.dart';

class PaymentController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns the created [Payment] on success, or `null` on failure (check
  /// `state.error` for the reason).
  Future<Payment?> pay({
    required String orderId,
    required String method,
    required num totalAmount,
    num? amountGiven,
    required String processedBy,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => ref.read(paymentServiceProvider).payOrder(
          orderId: orderId,
          method: method,
          totalAmount: totalAmount,
          amountGiven: amountGiven,
          processedBy: processedBy,
        ));
    state = result.hasError ? AsyncError(result.error!, result.stackTrace!) : const AsyncData(null);
    return result.value;
  }
}

final paymentControllerProvider =
    AsyncNotifierProvider<PaymentController, void>(PaymentController.new);
