import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../models/financial_summary.dart';
import '../../providers/report_provider.dart';

enum _Metric { sales, purchases, expenses }

class FinancialReportScreen extends ConsumerStatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  ConsumerState<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends ConsumerState<FinancialReportScreen> {
  _Metric _selected = _Metric.sales;

  Future<void> _pickPeriod() async {
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
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(financialSummaryProvider);
    final period = ref.watch(financialPeriodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keuangan')),
      body: AsyncValueWidget(
        value: summaryAsync,
        data: (summary) {
          final (dailyData, chartColor, chartLabel) = switch (_selected) {
            _Metric.sales => (summary.dailySales, const Color(0xFF1E7A5F), 'Penjualan'),
            _Metric.purchases => (summary.dailyPurchases, const Color(0xFFB25E00), 'Belanja Bahan Baku'),
            _Metric.expenses => (summary.dailyExpenses, const Color(0xFFC62828), 'Pengeluaran Lain'),
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OutlinedButton.icon(
                onPressed: _pickPeriod,
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
                selected: _selected == _Metric.sales,
                onTap: () => setState(() => _selected = _Metric.sales),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Belanja Bahan Baku',
                value: summary.totalIngredientPurchases,
                color: const Color(0xFFB25E00),
                icon: Icons.shopping_cart_outlined,
                selected: _selected == _Metric.purchases,
                onTap: () => setState(() => _selected = _Metric.purchases),
              ),
              const SizedBox(height: 12),
              _SummaryCard(
                label: 'Pengeluaran Lain',
                value: summary.totalExpenses,
                color: const Color(0xFFC62828),
                icon: Icons.receipt_long_outlined,
                selected: _selected == _Metric.expenses,
                onTap: () => setState(() => _selected = _Metric.expenses),
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
              Text('Tren $chartLabel Harian', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Ketuk salah satu kartu di atas untuk melihat tren datanya di sini.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: dailyData.isEmpty
                    ? Center(child: Text('Belum ada data $chartLabel pada periode ini.'))
                    : _TrendChart(dailyData: dailyData, color: chartColor),
              ),
            ],
          );
        },
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
    this.selected = false,
    this.onTap,
  });

  final String label;
  final num value;
  final Color color;
  final IconData icon;
  final bool emphasize;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected ? BorderSide(color: color, width: 1.6) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected ? 0.22 : 0.12),
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
              if (onTap != null)
                Icon(
                  selected ? Icons.bar_chart_rounded : Icons.chevron_right_rounded,
                  color: selected ? color : Theme.of(context).colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.dailyData, required this.color});

  final List<DailyTotal> dailyData;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxY = dailyData.map((e) => e.amount).fold<num>(0, (a, b) => a > b ? a : b);

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
                if (index < 0 || index >= dailyData.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    AppFormat.dateShort(dailyData[index].date).substring(0, 5),
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
              AppFormat.rupiah(dailyData[group.x].amount),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < dailyData.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailyData[i].amount.toDouble(),
                  color: color,
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
