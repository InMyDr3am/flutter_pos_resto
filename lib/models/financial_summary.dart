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
    required this.dailyPurchases,
    required this.dailyExpenses,
  });

  final num totalSales;
  final num totalIngredientPurchases;
  final num totalExpenses;
  final List<DailyTotal> dailySales;
  final List<DailyTotal> dailyPurchases;
  final List<DailyTotal> dailyExpenses;

  num get totalOutcome => totalIngredientPurchases + totalExpenses;
  num get netProfit => totalSales - totalOutcome;
}
