import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/order_detail.dart';
import 'supabase_client.dart';

class OrderDraftItem {
  const OrderDraftItem({
    required this.menuItemId,
    required this.quantity,
    required this.priceAtOrder,
    this.note,
  });

  final String menuItemId;
  final int quantity;
  final num priceAtOrder;
  final String? note;

  Map<String, dynamic> toJson(String orderId) => {
        'order_id': orderId,
        'menu_item_id': menuItemId,
        'quantity': quantity,
        'note': note,
        'price_at_order': priceAtOrder,
      };
}

class OrderService {
  final SupabaseClient _db = AppSupabase.client;

  static const _detailSelect = '*, order_items(*, menu_items(name)), payments(*)';

  Future<OrderDetail> createOrder({
    required String tableNumber,
    required String customerName,
    required DateTime orderDate,
    required List<OrderDraftItem> items,
    required String createdBy,
  }) async {
    final orderRow = await _db
        .from(SupaTables.orders)
        .insert({
          'table_number': tableNumber,
          'customer_name': customerName,
          'order_date': orderDate.toIso8601String().split('T').first,
          'status': OrderStatus.onProcess,
          'created_by': createdBy,
        })
        .select()
        .single();

    final orderId = orderRow['id'] as String;

    await _db.from(SupaTables.orderItems).insert(items.map((e) => e.toJson(orderId)).toList());

    final full =
        await _db.from(SupaTables.orders).select(_detailSelect).eq('id', orderId).single();
    return OrderDetail.fromJson(full);
  }

  /// Realtime feed of orders in [status], with items eagerly loaded so the
  /// kitchen / cashier screens can render without an extra round trip.
  ///
  /// Deliberately does *not* filter the underlying `.stream()` by status:
  /// Supabase Realtime only broadcasts an UPDATE to subscribers whose filter
  /// matches the row's *new* value, so a row leaving the filter (e.g.
  /// `served` -> `paid`) would never notify a `status=eq.served` subscriber,
  /// leaving stale rows on screen. Instead we stream every order and filter
  /// client-side so every transition is observed.
  Stream<List<OrderDetail>> watchOrdersByStatus(String status) {
    return _db.from(SupaTables.orders).stream(primaryKey: ['id']).order('created_at').asyncMap(
      (rows) async {
        final ids = rows.where((r) => r['status'] == status).map((r) => r['id'] as String).toList();
        if (ids.isEmpty) return <OrderDetail>[];
        final detailed = await _db
            .from(SupaTables.orders)
            .select(_detailSelect)
            .inFilter('id', ids)
            .order('created_at');
        return detailed.map(OrderDetail.fromJson).toList();
      },
    );
  }

  Future<void> markServed(String orderId) async {
    await _db
        .from(SupaTables.orders)
        .update({'status': OrderStatus.served, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', orderId);
  }
}
