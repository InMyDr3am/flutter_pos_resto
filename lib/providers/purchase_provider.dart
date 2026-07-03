import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/purchase_detail.dart';
import '../services/purchase_service.dart';
import 'ingredient_provider.dart';
import 'purchase_draft_provider.dart';
import 'service_providers.dart';

class DateRangeFilter {
  const DateRangeFilter({this.from, this.to});

  final DateTime? from;
  final DateTime? to;
}

class PurchaseDateFilterNotifier extends Notifier<DateRangeFilter> {
  @override
  DateRangeFilter build() => const DateRangeFilter();

  void set(DateTime? from, DateTime? to) => state = DateRangeFilter(from: from, to: to);

  void clear() => state = const DateRangeFilter();
}

final purchaseDateFilterProvider =
    NotifierProvider<PurchaseDateFilterNotifier, DateRangeFilter>(PurchaseDateFilterNotifier.new);

final purchasesProvider = FutureProvider<List<PurchaseDetail>>((ref) {
  final filter = ref.watch(purchaseDateFilterProvider);
  return ref.watch(purchaseServiceProvider).fetchPurchases(from: filter.from, to: filter.to);
});

class PurchaseController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submitPurchase(String createdBy) async {
    final draft = ref.read(purchaseDraftProvider);
    if (!draft.isValid) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(purchaseServiceProvider).createPurchase(
            purchaseDate: draft.purchaseDate,
            notes: draft.notes.trim().isEmpty ? null : draft.notes.trim(),
            createdBy: createdBy,
            items: draft.lines
                .map((l) => PurchaseDraftItem(
                      ingredientId: l.ingredient.id,
                      quantity: l.quantity,
                      unitPrice: l.unitPrice,
                    ))
                .toList(),
          );
    });

    if (!state.hasError) {
      ref.read(purchaseDraftProvider.notifier).clear();
      ref.invalidate(purchasesProvider);
      // Stock quantity is auto-updated by a DB trigger on insert.
      ref.invalidate(ingredientsProvider);
      return true;
    }
    return false;
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(purchaseServiceProvider).deletePurchase(id));
    ref.invalidate(purchasesProvider);
    ref.invalidate(ingredientsProvider);
  }
}

final purchaseControllerProvider =
    AsyncNotifierProvider<PurchaseController, void>(PurchaseController.new);
