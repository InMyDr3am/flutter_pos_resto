import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/purchase_detail.dart';
import '../../providers/purchase_provider.dart';
import 'purchase_form_screen.dart';

class PurchaseListScreen extends ConsumerWidget {
  const PurchaseListScreen({super.key});

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (range != null) {
      ref.read(purchaseDateFilterProvider.notifier).set(range.start, range.end);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final filter = ref.watch(purchaseDateFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belanja Bahan Baku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () => _pickDateRange(context, ref),
          ),
          if (filter.from != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: () => ref.read(purchaseDateFilterProvider.notifier).clear(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PurchaseFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Catat Belanja'),
      ),
      body: Column(
        children: [
          if (filter.from != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(
                    '${AppFormat.dateShort(filter.from!)} - ${AppFormat.dateShort(filter.to!)}',
                  ),
                ),
              ),
            ),
          Expanded(
            child: AsyncValueWidget(
              value: purchasesAsync,
              data: (purchases) {
                if (purchases.isEmpty) {
                  return const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Belum ada riwayat belanja',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: purchases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _PurchaseCard(purchase: purchases[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends ConsumerWidget {
  const _PurchaseCard({required this.purchase});

  final PurchaseDetail purchase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          AppFormat.dateLong(purchase.batch.purchaseDate),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${purchase.items.length} bahan baku'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppFormat.rupiah(purchase.totalAmount),
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
                for (final item in purchase.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.ingredientName ?? '-'} · ${item.quantity} ${item.ingredientUnit ?? ''} '
                            '× ${AppFormat.rupiah(item.unitPrice)}',
                          ),
                        ),
                        Text(AppFormat.rupiah(item.totalPrice)),
                      ],
                    ),
                  ),
                if (purchase.batch.notes != null && purchase.batch.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    purchase.batch.notes!,
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
                        title: 'Hapus belanja ini?',
                        message: 'Seluruh item dalam transaksi ini akan dihapus permanen.',
                      );
                      if (confirmed) {
                        await ref.read(purchaseControllerProvider.notifier).delete(purchase.batch.id);
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
