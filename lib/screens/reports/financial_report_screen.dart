import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../models/financial_summary.dart';
import '../../providers/report_provider.dart';

class FinancialReportScreen extends ConsumerWidget {
  const FinancialReportScreen({super.key});

  Future<void> _pickPeriod(BuildContext context, WidgetRef ref) async {
    final period = ref.read(financialPeriodProvider);
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(start: period.from, end: period.to),
    );
    if (range != null) {
      ref.read(financialPeriodProvider.notifier).set(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final period = ref.watch(financialPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keuangan')),
      body: AsyncValueWidget(
        value: summaryAsync,
        data: (summary) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickPeriod(context, ref),
              icon: const Icon(Icons.date_range_outlined, size: 18),
              label: Text(
                '${AppFormat.dateShort(period.from)} - ${AppFormat.dateShort(period.to)}',
              ),
            ),
            const SizedBox(height: 16),
            _SummaryCard(
              label: 'Total Penjualan',
              value: summary.totalSales,
              color: const Color(0xFF1E7A5F),
              icon: Icons.trending_up_rounded,
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              label: 'Belanja Bahan Baku',
              value: summary.totalIngredientPurchases,
              color: const Color(0xFFB25E00),
              icon: Icons.shopping_cart_outlined,
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              label: 'Pengeluaran Lain',
              value: summary.totalExpenses,
              color: const Color(0xFFB25E00),
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              label: 'Laba Bersih',
              value: summary.netProfit,
              color: summary.netProfit >= 0 ? const Color(0xFF1E7A5F) : const Color(0xFFC62828),
              icon: Icons.account_balance_wallet_outlined,
              emphasize: true,
            ),
            const SizedBox(height: 24),
            Text('Tren Penjualan Harian', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: summary.dailySales.isEmpty
                  ? const Center(child: Text('Belum ada data penjualan pada periode ini.'))
                  : _SalesTrendChart(dailySales: summary.dailySales),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.emphasize = false,
  });

  final String label;
  final num value;
  final Color color;
  final IconData icon;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    AppFormat.rupiah(value),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: emphasize ? 20 : 16,
                      color: emphasize ? color : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({required this.dailySales});

  final List<DailyTotal> dailySales;

  @override
  Widget build(BuildContext context) {
    final maxY = dailySales.map((e) => e.amount).fold<num>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY.toDouble() * 1.2,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dailySales.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppFormat.dateShort(dailySales[index].date).substring(0, 5),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              AppFormat.rupiah(dailySales[group.x].amount),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < dailySales.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailySales[i].amount.toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
