import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/financial_summary.dart';
import '../models/order_detail.dart';
import 'order_provider.dart';
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

/// Filters the realtime `paidOrdersProvider` feed instead of running a
/// one-off query, so a payment made anywhere shows up here the instant it
/// happens — no manual re-filter needed.
final salesReportProvider = Provider<AsyncValue<List<OrderDetail>>>((ref) {
  final filter = ref.watch(salesReportFilterProvider);
  final ordersAsync = ref.watch(paidOrdersProvider);

  return ordersAsync.whenData((orders) {
    return orders.where((detail) {
      final order = detail.order;
      if (filter.from != null && order.orderDate.isBefore(filter.from!)) return false;
      if (filter.to != null && order.orderDate.isAfter(filter.to!)) return false;
      if (filter.customerName != null &&
          filter.customerName!.trim().isNotEmpty &&
          !order.customerName.toLowerCase().contains(filter.customerName!.trim().toLowerCase())) {
        return false;
      }
      if (filter.tableNumber != null &&
          filter.tableNumber!.trim().isNotEmpty &&
          !order.tableNumber.toLowerCase().contains(filter.tableNumber!.trim().toLowerCase())) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.order.orderDate.compareTo(a.order.orderDate));
  });
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
