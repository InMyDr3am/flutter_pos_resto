import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

class PaymentController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> pay({
    required String orderId,
    required String method,
    required num totalAmount,
    num? amountGiven,
    required String processedBy,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(paymentServiceProvider).payOrder(
          orderId: orderId,
          method: method,
          totalAmount: totalAmount,
          amountGiven: amountGiven,
          processedBy: processedBy,
        ));
    return !state.hasError;
  }
}

final paymentControllerProvider =
    AsyncNotifierProvider<PaymentController, void>(PaymentController.new);
