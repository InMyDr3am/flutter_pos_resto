import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/expense_detail.dart';
import '../../providers/expense_provider.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (range != null) {
      ref.read(expenseDateFilterProvider.notifier).set(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final filter = ref.watch(expenseDateFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _pickDateRange(context, ref),
          ),
          if (filter.from != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: () => ref.read(expenseDateFilterProvider.notifier).clear(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Pengeluaran Baru'),
      ),
      body: AsyncValueWidget(
        value: expensesAsync,
        data: (expenses) {
          if (expenses.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Belum ada pengeluaran');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: expenses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _ExpenseCard(expense: expenses[index]),
          );
        },
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  const _ExpenseCard({required this.expense});

  final ExpenseDetail expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          AppFormat.dateLong(expense.batch.expenseDate),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${expense.items.length} pengeluaran'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppFormat.rupiah(expense.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in expense.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (item.description != null && item.description!.isNotEmpty)
                                Text(
                                  item.description!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        Text(AppFormat.rupiah(item.amount)),
                      ],
                    ),
                  ),
                if (expense.batch.notes != null && expense.batch.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    expense.batch.notes!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Hapus pengeluaran ini?',
                        message: 'Seluruh item dalam transaksi ini akan dihapus permanen.',
                      );
                      if (confirmed) {
                        await ref.read(expenseControllerProvider.notifier).delete(expense.batch.id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
