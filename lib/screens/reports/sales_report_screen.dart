import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/export_print_actions.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/order_detail.dart';
import '../../providers/report_provider.dart';
import '../../providers/service_providers.dart';

/// List of `paid` transactions, filterable by date/customer/table.
///
/// Used both as a standalone route (`/owner/sales-report`) and embedded as a
/// tab inside the cashier home screen — pass [embedded] to skip the extra
/// `Scaffold`/`AppBar` in the latter case.
class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  final _customerController = TextEditingController();
  final _tableController = TextEditingController();

  @override
  void dispose() {
    _customerController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filter = ref.read(salesReportFilterProvider);
    ref.read(salesReportFilterProvider.notifier).set(
          from: filter.from,
          to: filter.to,
          customerName: _customerController.text,
          tableNumber: _tableController.text,
        );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (range != null) {
      final filter = ref.read(salesReportFilterProvider);
      ref.read(salesReportFilterProvider.notifier).set(
            from: range.start,
            to: range.end,
            customerName: filter.customerName,
            tableNumber: filter.tableNumber,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(salesReportProvider);
    final filter = ref.watch(salesReportFilterProvider);

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerController,
                  decoration: const InputDecoration(hintText: 'Nama pembeli', isDense: true),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tableController,
                  decoration: const InputDecoration(hintText: 'No. meja', isDense: true),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              IconButton(icon: const Icon(Icons.search_rounded), onPressed: _applyFilters),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range_outlined, size: 18),
                  label: Text(
                    filter.from == null
                        ? 'Semua tanggal'
                        : '${AppFormat.dateShort(filter.from!)} - ${AppFormat.dateShort(filter.to!)}',
                  ),
                ),
              ),
              if (filter.from != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => ref.read(salesReportFilterProvider.notifier).set(
                        customerName: filter.customerName,
                        tableNumber: filter.tableNumber,
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AsyncValueWidget(
            value: reportAsync,
            data: (orders) {
              if (orders.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi lunas',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _SalesCard(order: orders[index]),
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          ExportPrintActions(
            onExport: () =>
                ref.read(excelExportServiceProvider).exportSalesReport(reportAsync.value ?? []),
            onPrint: () =>
                ref.read(pdfReportServiceProvider).printSalesReport(reportAsync.value ?? []),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          '${order.order.customerName} · Meja ${order.order.tableNumber}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(AppFormat.dateLong(order.order.orderDate)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppFormat.rupiah(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const StatusBadge(status: 'paid'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.menuItemName ?? '-'}'
                            '${(item.note?.isNotEmpty ?? false) ? ' (${item.note})' : ''}',
                          ),
                        ),
                        Text(AppFormat.rupiah(item.subtotal)),
                      ],
                    ),
                  ),
                const Divider(),
                if (order.payment != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Metode bayar'),
                      Text(order.payment!.paymentMethod.toUpperCase()),
                    ],
                  ),
                  if (order.payment!.paymentMethod == 'cash') ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Uang diterima'),
                        Text(AppFormat.rupiah(order.payment!.amountGiven)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian'),
                        Text(AppFormat.rupiah(order.payment!.changeAmount)),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
