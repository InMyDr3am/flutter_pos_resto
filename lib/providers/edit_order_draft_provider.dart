import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item.dart';
import '../models/order_detail.dart';
import 'cart_provider.dart' show CartLine;

/// Same shape as [CartState] (see `cart_provider.dart`) but kept as a
/// separate provider so editing an existing order never collides with the
/// cashier's in-progress "new order" cart.
class EditOrderDraftState {
  EditOrderDraftState({
    this.orderId,
    List<CartLine>? lines,
    this.tableNumber = '',
    this.customerName = '',
    DateTime? orderDate,
  })  : lines = lines ?? const [],
        orderDate = orderDate ?? DateTime.now();

  final String? orderId;
  final List<CartLine> lines;
  final String tableNumber;
  final String customerName;
  final DateTime orderDate;

  num get total => lines.fold<num>(0, (sum, l) => sum + l.subtotal);

  bool get isValid =>
      lines.isNotEmpty && tableNumber.trim().isNotEmpty && customerName.trim().isNotEmpty;

  EditOrderDraftState copyWith({
    String? orderId,
    List<CartLine>? lines,
    String? tableNumber,
    String? customerName,
    DateTime? orderDate,
  }) =>
      EditOrderDraftState(
        orderId: orderId ?? this.orderId,
        lines: lines ?? this.lines,
        tableNumber: tableNumber ?? this.tableNumber,
        customerName: customerName ?? this.customerName,
        orderDate: orderDate ?? this.orderDate,
      );
}

class EditOrderDraftNotifier extends Notifier<EditOrderDraftState> {
  @override
  EditOrderDraftState build() => EditOrderDraftState();

  /// Seeds the draft from an existing order so the edit screen starts from
  /// its current items/details.
  void loadFrom(OrderDetail detail) {
    final lines = detail.items.map((item) {
      final menuItem = MenuItem(
        id: item.menuItemId,
        name: item.menuItemName ?? 'Menu',
        price: item.priceAtOrder,
        isAvailable: true,
        createdAt: item.createdAt,
        updatedAt: item.createdAt,
      );
      return CartLine(menuItem: menuItem, quantity: item.quantity, note: item.note);
    }).toList();

    state = EditOrderDraftState(
      orderId: detail.order.id,
      lines: lines,
      tableNumber: detail.order.tableNumber,
      customerName: detail.order.customerName,
      orderDate: detail.order.orderDate,
    );
  }

  void increment(MenuItem item) {
    final lines = [...state.lines];
    final idx = lines.indexWhere((l) => l.menuItem.id == item.id);
    if (idx == -1) {
      lines.add(CartLine(menuItem: item, quantity: 1));
    } else {
      lines[idx] = lines[idx].copyWith(quantity: lines[idx].quantity + 1);
    }
    state = state.copyWith(lines: lines);
  }

  void decrement(String menuItemId) {
    final lines = [...state.lines];
    final idx = lines.indexWhere((l) => l.menuItem.id == menuItemId);
    if (idx == -1) return;
    if (lines[idx].quantity <= 1) {
      lines.removeAt(idx);
    } else {
      lines[idx] = lines[idx].copyWith(quantity: lines[idx].quantity - 1);
    }
    state = state.copyWith(lines: lines);
  }

  void removeLine(String menuItemId) {
    state = state.copyWith(lines: state.lines.where((l) => l.menuItem.id != menuItemId).toList());
  }

  void setNote(String menuItemId, String note) {
    final lines = state.lines
        .map((l) => l.menuItem.id == menuItemId ? l.copyWith(note: note) : l)
        .toList();
    state = state.copyWith(lines: lines);
  }

  void setTableNumber(String value) => state = state.copyWith(tableNumber: value);

  void setCustomerName(String value) => state = state.copyWith(customerName: value);

  void setOrderDate(DateTime value) => state = state.copyWith(orderDate: value);

  void clear() => state = EditOrderDraftState();
}

final editOrderDraftProvider =
    NotifierProvider<EditOrderDraftNotifier, EditOrderDraftState>(EditOrderDraftNotifier.new);
