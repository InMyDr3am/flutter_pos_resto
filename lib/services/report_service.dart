import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/financial_summary.dart';
import 'supabase_client.dart';

class ReportService {
  final SupabaseClient _db = AppSupabase.client;

  Future<FinancialSummary> fetchFinancialSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final fromStr = from.toIso8601String().split('T').first;
    final toStr = to.toIso8601String().split('T').first;

    final salesRows = await _db
        .from(SupaTables.orders)
        .select('order_date, payments(total_amount)')
        .eq('status', OrderStatus.paid)
        .gte('order_date', fromStr)
        .lte('order_date', toStr);

    final purchaseRows = await _db
        .from(SupaTables.ingredientPurchaseItems)
        .select('total_price, ingredient_purchases!inner(purchase_date)')
        .gte('ingredient_purchases.purchase_date', fromStr)
        .lte('ingredient_purchases.purchase_date', toStr);

    final expenseRows = await _db
        .from(SupaTables.expenseItems)
        .select('amount, expenses!inner(expense_date)')
        .gte('expenses.expense_date', fromStr)
        .lte('expenses.expense_date', toStr);

    final salesDaily = <String, num>{};
    num totalSales = 0;
    for (final row in salesRows) {
      final payments = (row['payments'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final orderTotal = payments.fold<num>(0, (sum, p) => sum + (p['total_amount'] as num? ?? 0));
      totalSales += orderTotal;
      final date = row['order_date'] as String;
      salesDaily[date] = (salesDaily[date] ?? 0) + orderTotal;
    }

    final purchaseDaily = <String, num>{};
    num totalPurchases = 0;
    for (final row in purchaseRows) {
      final price = row['total_price'] as num? ?? 0;
      totalPurchases += price;
      final date = (row['ingredient_purchases'] as Map<String, dynamic>)['purchase_date'] as String;
      purchaseDaily[date] = (purchaseDaily[date] ?? 0) + price;
    }

    final expenseDaily = <String, num>{};
    num totalExpenses = 0;
    for (final row in expenseRows) {
      final amount = row['amount'] as num? ?? 0;
      totalExpenses += amount;
      final date = (row['expenses'] as Map<String, dynamic>)['expense_date'] as String;
      expenseDaily[date] = (expenseDaily[date] ?? 0) + amount;
    }

    return FinancialSummary(
      totalSales: totalSales,
      totalIngredientPurchases: totalPurchases,
      totalExpenses: totalExpenses,
      dailySales: _toSortedDailyTotals(salesDaily),
      dailyPurchases: _toSortedDailyTotals(purchaseDaily),
      dailyExpenses: _toSortedDailyTotals(expenseDaily),
    );
  }

  List<DailyTotal> _toSortedDailyTotals(Map<String, num> byDate) {
    return byDate.entries.map((e) => DailyTotal(date: DateTime.parse(e.key), amount: e.value)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
