import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item.dart';

/// A single line in the cashier's in-progress order (one entry per menu
/// item, with its own quantity and note).
class CartLine {
  const CartLine({required this.menuItem, required this.quantity, this.note});

  final MenuItem menuItem;
  final int quantity;
  final String? note;

  num get subtotal => menuItem.price * quantity;

  CartLine copyWith({int? quantity, String? note}) => CartLine(
        menuItem: menuItem,
        quantity: quantity ?? this.quantity,
        note: note ?? this.note,
      );
}

class CartState {
  CartState({List<CartLine>? lines, this.tableNumber = '', this.customerName = '', DateTime? orderDate})
      : lines = lines ?? const [],
        orderDate = orderDate ?? DateTime.now();

  final List<CartLine> lines;
  final String tableNumber;
  final String customerName;
  final DateTime orderDate;

  num get total => lines.fold<num>(0, (sum, l) => sum + l.subtotal);

  int get itemCount => lines.fold<int>(0, (sum, l) => sum + l.quantity);

  bool get isValid => lines.isNotEmpty && tableNumber.trim().isNotEmpty && customerName.trim().isNotEmpty;

  CartState copyWith({
    List<CartLine>? lines,
    String? tableNumber,
    String? customerName,
    DateTime? orderDate,
  }) =>
      CartState(
        lines: lines ?? this.lines,
        tableNumber: tableNumber ?? this.tableNumber,
        customerName: customerName ?? this.customerName,
        orderDate: orderDate ?? this.orderDate,
      );
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => CartState();

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

  void clear() => state = CartState();
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
