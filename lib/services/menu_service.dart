import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import 'supabase_client.dart';

class MenuService {
  final SupabaseClient _db = AppSupabase.client;

  Future<List<MenuCategory>> fetchCategories() async {
    final rows = await _db.from(SupaTables.menuCategories).select().order('name');
    return rows.map(MenuCategory.fromJson).toList();
  }

  Future<MenuCategory> createCategory(String name) async {
    final row =
        await _db.from(SupaTables.menuCategories).insert({'name': name}).select().single();
    return MenuCategory.fromJson(row);
  }

  Future<List<MenuItem>> fetchMenuItems({String? search, String? categoryId}) async {
    var query = _db.from(SupaTables.menuItems).select('*, menu_categories(name)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name', '%${search.trim()}%');
    }

    final rows = await query.order('name');
    return rows.map(MenuItem.fromJson).toList();
  }

  Future<MenuItem> createMenuItem(MenuItem item) async {
    final row =
        await _db.from(SupaTables.menuItems).insert(item.toJson()).select().single();
    return MenuItem.fromJson(row);
  }

  Future<MenuItem> updateMenuItem(String id, Map<String, dynamic> changes) async {
    final row = await _db
        .from(SupaTables.menuItems)
        .update({...changes, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .select()
        .single();
    return MenuItem.fromJson(row);
  }

  Future<void> deleteMenuItem(String id) async {
    await _db.from(SupaTables.menuItems).delete().eq('id', id);
  }

  Future<String> uploadMenuPhoto(Uint8List bytes, String fileName) async {
    final path = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _db.storage.from(SupaBuckets.menuPhotos).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _db.storage.from(SupaBuckets.menuPhotos).getPublicUrl(path);
  }
}
