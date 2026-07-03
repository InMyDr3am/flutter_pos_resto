import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_detail.dart';
import '../services/expense_service.dart';
import 'expense_draft_provider.dart';
import 'purchase_provider.dart' show DateRangeFilter;
import 'service_providers.dart';

class ExpenseDateFilterNotifier extends Notifier<DateRangeFilter> {
  @override
  DateRangeFilter build() => const DateRangeFilter();

  void set(DateTime? from, DateTime? to) => state = DateRangeFilter(from: from, to: to);

  void clear() => state = const DateRangeFilter();
}

final expenseDateFilterProvider =
    NotifierProvider<ExpenseDateFilterNotifier, DateRangeFilter>(ExpenseDateFilterNotifier.new);

final expensesProvider = FutureProvider<List<ExpenseDetail>>((ref) {
  final filter = ref.watch(expenseDateFilterProvider);
  return ref.watch(expenseServiceProvider).fetchExpenses(from: filter.from, to: filter.to);
});

class ExpenseController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submitExpense(String createdBy) async {
    final draft = ref.read(expenseDraftProvider);
    if (!draft.isValid) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(expenseServiceProvider).createExpense(
            expenseDate: draft.expenseDate,
            notes: draft.notes.trim().isEmpty ? null : draft.notes.trim(),
            createdBy: createdBy,
            items: draft.lines
                .map((l) => ExpenseDraftItem(
                      category: l.category,
                      description: l.description,
                      amount: l.amount,
                    ))
                .toList(),
          );
    });

    if (!state.hasError) {
      ref.read(expenseDraftProvider.notifier).clear();
      ref.invalidate(expensesProvider);
      return true;
    }
    return false;
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(expenseServiceProvider).deleteExpense(id));
    ref.invalidate(expensesProvider);
  }
}

final expenseControllerProvider =
    AsyncNotifierProvider<ExpenseController, void>(ExpenseController.new);
