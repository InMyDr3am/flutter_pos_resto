import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/expense_detail.dart';
import 'supabase_client.dart';

class ExpenseDraftItem {
  const ExpenseDraftItem({
    required this.category,
    this.description,
    required this.amount,
  });

  final String category;
  final String? description;
  final num amount;

  Map<String, dynamic> toJson(String expenseId) => {
        'expense_id': expenseId,
        'category': category,
        'description': description,
        'amount': amount,
      };
}

class ExpenseService {
  final SupabaseClient _db = AppSupabase.client;

  static const _detailSelect = '*, expense_items(*)';

  Future<List<ExpenseDetail>> fetchExpenses({DateTime? from, DateTime? to}) async {
    var query = _db.from(SupaTables.expenses).select(_detailSelect);

    if (from != null) {
      query = query.gte('expense_date', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte('expense_date', to.toIso8601String().split('T').first);
    }

    final rows = await query.order('expense_date', ascending: false);
    return rows.map(ExpenseDetail.fromJson).toList();
  }

  Future<ExpenseDetail> createExpense({
    required DateTime expenseDate,
    String? notes,
    required String createdBy,
    required List<ExpenseDraftItem> items,
  }) async {
    final batchRow = await _db
        .from(SupaTables.expenses)
        .insert({
          'expense_date': expenseDate.toIso8601String().split('T').first,
          'notes': notes,
          'created_by': createdBy,
        })
        .select()
        .single();

    final expenseId = batchRow['id'] as String;

    await _db.from(SupaTables.expenseItems).insert(items.map((e) => e.toJson(expenseId)).toList());

    final full =
        await _db.from(SupaTables.expenses).select(_detailSelect).eq('id', expenseId).single();
    return ExpenseDetail.fromJson(full);
  }

  Future<void> deleteExpense(String id) async {
    await _db.from(SupaTables.expenses).delete().eq('id', id);
  }
}
