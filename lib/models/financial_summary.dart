class DailyTotal {
  const DailyTotal({required this.date, required this.amount});

  final DateTime date;
  final num amount;
}

class FinancialSummary {
  const FinancialSummary({
    required this.totalSales,
    required this.totalIngredientPurchases,
    required this.totalExpenses,
    required this.dailySales,
  });

  final num totalSales;
  final num totalIngredientPurchases;
  final num totalExpenses;
  final List<DailyTotal> dailySales;

  num get totalOutcome => totalIngredientPurchases + totalExpenses;
  num get netProfit => totalSales - totalOutcome;
}
