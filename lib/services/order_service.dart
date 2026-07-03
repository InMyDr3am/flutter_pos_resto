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
  Stream<List<OrderDetail>> watchOrdersByStatus(String status) {
    return _db
        .from(SupaTables.orders)
        .stream(primaryKey: ['id'])
        .eq('status', status)
        .order('created_at')
        .asyncMap((rows) async {
      if (rows.isEmpty) return <OrderDetail>[];
      final ids = rows.map((r) => r['id'] as String).toList();
      final detailed = await _db
          .from(SupaTables.orders)
          .select(_detailSelect)
          .inFilter('id', ids)
          .order('created_at');
      return detailed.map(OrderDetail.fromJson).toList();
    });
  }

  Future<void> markServed(String orderId) async {
    await _db
        .from(SupaTables.orders)
        .update({'status': OrderStatus.served, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', orderId);
  }

  Future<List<OrderDetail>> fetchSalesReport({
    DateTime? from,
    DateTime? to,
    String? customerName,
    String? tableNumber,
  }) async {
    var query = _db.from(SupaTables.orders).select(_detailSelect).eq('status', OrderStatus.paid);

    if (from != null) {
      query = query.gte('order_date', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte('order_date', to.toIso8601String().split('T').first);
    }
    if (customerName != null && customerName.trim().isNotEmpty) {
      query = query.ilike('customer_name', '%${customerName.trim()}%');
    }
    if (tableNumber != null && tableNumber.trim().isNotEmpty) {
      query = query.ilike('table_number', '%${tableNumber.trim()}%');
    }

    final rows = await query.order('order_date', ascending: false);
    return rows.map(OrderDetail.fromJson).toList();
  }
}
