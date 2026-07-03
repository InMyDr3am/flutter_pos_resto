import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/ingredient.dart';
import 'supabase_client.dart';

class IngredientService {
  final SupabaseClient _db = AppSupabase.client;

  Future<List<Ingredient>> fetchIngredients({String? search}) async {
    var query = _db.from(SupaTables.ingredients).select();
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name', '%${search.trim()}%');
    }
    final rows = await query.order('name');
    return rows.map(Ingredient.fromJson).toList();
  }

  Future<Ingredient> createIngredient({
    required String name,
    required String unit,
    num stockQuantity = 0,
  }) async {
    final row = await _db
        .from(SupaTables.ingredients)
        .insert({'name': name, 'unit': unit, 'stock_quantity': stockQuantity})
        .select()
        .single();
    return Ingredient.fromJson(row);
  }

  Future<Ingredient> updateIngredient(String id, Map<String, dynamic> changes) async {
    final row =
        await _db.from(SupaTables.ingredients).update(changes).eq('id', id).select().single();
    return Ingredient.fromJson(row);
  }

  Future<void> deleteIngredient(String id) async {
    await _db.from(SupaTables.ingredients).delete().eq('id', id);
  }
}
