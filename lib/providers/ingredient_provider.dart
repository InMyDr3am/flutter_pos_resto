import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ingredient.dart';
import 'service_providers.dart';

class IngredientSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final ingredientSearchProvider =
    NotifierProvider<IngredientSearchNotifier, String>(IngredientSearchNotifier.new);

final ingredientsProvider = FutureProvider<List<Ingredient>>((ref) {
  final search = ref.watch(ingredientSearchProvider);
  return ref.watch(ingredientServiceProvider).fetchIngredients(search: search);
});

class IngredientController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    ref.invalidate(ingredientsProvider);
  }

  Future<void> create({required String name, required String unit, num stockQuantity = 0}) =>
      _run(() async {
        await ref.read(ingredientServiceProvider).createIngredient(
              name: name,
              unit: unit,
              stockQuantity: stockQuantity,
            );
      });

  Future<void> updateIngredient(String id, Map<String, dynamic> changes) => _run(() async {
        await ref.read(ingredientServiceProvider).updateIngredient(id, changes);
      });

  Future<void> delete(String id) => _run(() async {
        await ref.read(ingredientServiceProvider).deleteIngredient(id);
      });
}

final ingredientControllerProvider =
    AsyncNotifierProvider<IngredientController, void>(IngredientController.new);
