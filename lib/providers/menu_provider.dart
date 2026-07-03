import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_category.dart';
import '../models/menu_item.dart';
import 'service_providers.dart';

class MenuFilter {
  const MenuFilter({this.search = '', this.categoryId});

  final String search;
  final String? categoryId;

  MenuFilter copyWith({String? search, String? categoryId}) => MenuFilter(
        search: search ?? this.search,
        categoryId: categoryId,
      );
}

class MenuFilterNotifier extends Notifier<MenuFilter> {
  @override
  MenuFilter build() => const MenuFilter();

  void setSearch(String value) => state = state.copyWith(search: value, categoryId: state.categoryId);

  void setCategory(String? categoryId) => state = MenuFilter(search: state.search, categoryId: categoryId);
}

final menuFilterProvider = NotifierProvider<MenuFilterNotifier, MenuFilter>(MenuFilterNotifier.new);

final menuCategoriesProvider = FutureProvider<List<MenuCategory>>((ref) {
  return ref.watch(menuServiceProvider).fetchCategories();
});

final menuItemsProvider = FutureProvider<List<MenuItem>>((ref) {
  final filter = ref.watch(menuFilterProvider);
  return ref.watch(menuServiceProvider).fetchMenuItems(
        search: filter.search,
        categoryId: filter.categoryId,
      );
});

/// Unfiltered menu list independent of [menuFilterProvider], so screens that
/// need their own local search (e.g. the order-edit screen) don't fight over
/// shared filter state with the menu list / new-order tab.
final allMenuItemsProvider = FutureProvider<List<MenuItem>>((ref) {
  return ref.watch(menuServiceProvider).fetchMenuItems();
});

class MenuController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    ref.invalidate(menuItemsProvider);
  }

  Future<void> createMenuItem(MenuItem item) => _run(() async {
        await ref.read(menuServiceProvider).createMenuItem(item);
      });

  Future<void> updateMenuItem(String id, Map<String, dynamic> changes) => _run(() async {
        await ref.read(menuServiceProvider).updateMenuItem(id, changes);
      });

  Future<void> deleteMenuItem(String id) => _run(() async {
        await ref.read(menuServiceProvider).deleteMenuItem(id);
      });

  Future<void> addCategory(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(menuServiceProvider).createCategory(name);
    });
    ref.invalidate(menuCategoriesProvider);
  }

  Future<String> uploadPhoto(Uint8List bytes, String fileName) {
    return ref.read(menuServiceProvider).uploadMenuPhoto(bytes, fileName);
  }
}

final menuControllerProvider = AsyncNotifierProvider<MenuController, void>(MenuController.new);
