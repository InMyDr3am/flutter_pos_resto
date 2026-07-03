import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/financial_summary.dart';
import '../models/order_detail.dart';
import 'service_providers.dart';

class SalesReportFilter {
  const SalesReportFilter({this.from, this.to, this.customerName, this.tableNumber});

  final DateTime? from;
  final DateTime? to;
  final String? customerName;
  final String? tableNumber;

  SalesReportFilter copyWith({
    DateTime? from,
    DateTime? to,
    String? customerName,
    String? tableNumber,
  }) =>
      SalesReportFilter(
        from: from ?? this.from,
        to: to ?? this.to,
        customerName: customerName ?? this.customerName,
        tableNumber: tableNumber ?? this.tableNumber,
      );
}

class SalesReportFilterNotifier extends Notifier<SalesReportFilter> {
  @override
  SalesReportFilter build() => const SalesReportFilter();

  void set({DateTime? from, DateTime? to, String? customerName, String? tableNumber}) {
    state = SalesReportFilter(
      from: from,
      to: to,
      customerName: customerName,
      tableNumber: tableNumber,
    );
  }
}

final salesReportFilterProvider =
    NotifierProvider<SalesReportFilterNotifier, SalesReportFilter>(SalesReportFilterNotifier.new);

final salesReportProvider = FutureProvider<List<OrderDetail>>((ref) {
  final filter = ref.watch(salesReportFilterProvider);
  return ref.watch(orderServiceProvider).fetchSalesReport(
        from: filter.from,
        to: filter.to,
        customerName: filter.customerName,
        tableNumber: filter.tableNumber,
      );
});

class FinancialPeriod {
  FinancialPeriod({DateTime? from, DateTime? to})
      : from = from ?? DateTime(DateTime.now().year, DateTime.now().month, 1),
        to = to ?? DateTime.now();

  final DateTime from;
  final DateTime to;
}

class FinancialPeriodNotifier extends Notifier<FinancialPeriod> {
  @override
  FinancialPeriod build() => FinancialPeriod();

  void set(DateTime from, DateTime to) => state = FinancialPeriod(from: from, to: to);
}

final financialPeriodProvider =
    NotifierProvider<FinancialPeriodNotifier, FinancialPeriod>(FinancialPeriodNotifier.new);

final financialSummaryProvider = FutureProvider<FinancialSummary>((ref) {
  final period = ref.watch(financialPeriodProvider);
  return ref.watch(reportServiceProvider).fetchFinancialSummary(from: period.from, to: period.to);
});
