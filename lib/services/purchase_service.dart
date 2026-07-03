import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/purchase_detail.dart';
import 'supabase_client.dart';

class PurchaseDraftItem {
  const PurchaseDraftItem({
    required this.ingredientId,
    required this.quantity,
    required this.unitPrice,
  });

  final String ingredientId;
  final num quantity;
  final num unitPrice;

  num get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toJson(String purchaseId) => {
        'purchase_id': purchaseId,
        'ingredient_id': ingredientId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
      };
}

class PurchaseService {
  final SupabaseClient _db = AppSupabase.client;

  static const _detailSelect = '*, ingredient_purchase_items(*, ingredients(name, unit))';

  /// Fetches purchase trips, optionally filtered by an inclusive date range.
  /// A database trigger keeps `ingredients.stock_quantity` in sync with each
  /// line item, so this service only needs to write the rows.
  Future<List<PurchaseDetail>> fetchPurchases({DateTime? from, DateTime? to}) async {
    var query = _db.from(SupaTables.ingredientPurchases).select(_detailSelect);

    if (from != null) {
      query = query.gte('purchase_date', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte('purchase_date', to.toIso8601String().split('T').first);
    }

    final rows = await query.order('purchase_date', ascending: false);
    return rows.map(PurchaseDetail.fromJson).toList();
  }

  Future<PurchaseDetail> createPurchase({
    required DateTime purchaseDate,
    String? notes,
    required String createdBy,
    required List<PurchaseDraftItem> items,
  }) async {
    final batchRow = await _db
        .from(SupaTables.ingredientPurchases)
        .insert({
          'purchase_date': purchaseDate.toIso8601String().split('T').first,
          'notes': notes,
          'created_by': createdBy,
        })
        .select()
        .single();

    final purchaseId = batchRow['id'] as String;

    await _db
        .from(SupaTables.ingredientPurchaseItems)
        .insert(items.map((e) => e.toJson(purchaseId)).toList());

    final full = await _db
        .from(SupaTables.ingredientPurchases)
        .select(_detailSelect)
        .eq('id', purchaseId)
        .single();
    return PurchaseDetail.fromJson(full);
  }

  Future<void> deletePurchase(String id) async {
    await _db.from(SupaTables.ingredientPurchases).delete().eq('id', id);
  }
}
