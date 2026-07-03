import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/order_detail.dart';
import '../services/order_service.dart' show OrderDraftItem;
import 'cart_provider.dart';
import 'service_providers.dart';

/// Orders currently being prepared — feeds the kitchen screen.
final kitchenOrdersProvider = StreamProvider<List<OrderDetail>>((ref) {
  return ref.watch(orderServiceProvider).watchOrdersByStatus(OrderStatus.onProcess);
});

/// Orders plated and ready to be paid — feeds the cashier/payment screen.
final servedOrdersProvider = StreamProvider<List<OrderDetail>>((ref) {
  return ref.watch(orderServiceProvider).watchOrdersByStatus(OrderStatus.served);
});

class OrderController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submitOrder(String createdBy) async {
    final cart = ref.read(cartProvider);
    if (!cart.isValid) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(orderServiceProvider).createOrder(
            tableNumber: cart.tableNumber,
            customerName: cart.customerName,
            orderDate: cart.orderDate,
            createdBy: createdBy,
            items: cart.lines
                .map((l) => OrderDraftItem(
                      menuItemId: l.menuItem.id,
                      quantity: l.quantity,
                      priceAtOrder: l.menuItem.price,
                      note: l.note,
                    ))
                .toList(),
          );
    });

    if (!state.hasError) {
      ref.read(cartProvider.notifier).clear();
      return true;
    }
    return false;
  }

  Future<void> markServed(String orderId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(orderServiceProvider).markServed(orderId));
  }
}

final orderControllerProvider = AsyncNotifierProvider<OrderController, void>(OrderController.new);
