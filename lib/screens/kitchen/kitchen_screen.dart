import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/order_detail.dart';
import '../../providers/order_provider.dart';

/// Live feed of `on_process` orders for kitchen/staff. Marking an order
/// "Sudah Dihidangkan" flips it to `served`, which removes it from this list
/// (via realtime) and surfaces it in the cashier's payment tab.
class KitchenScreen extends ConsumerWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(kitchenOrdersProvider);

    return AppScaffold(
      title: 'Pesanan Masuk',
      body: AsyncValueWidget(
        value: ordersAsync,
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.soup_kitchen_outlined,
              title: 'Belum ada pesanan masuk',
              message: 'Pesanan baru dari kasir akan muncul di sini secara langsung.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _KitchenOrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _KitchenOrderCard extends ConsumerWidget {
  const _KitchenOrderCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(orderControllerProvider).isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meja ${order.order.tableNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(AppFormat.time(order.order.createdAt)),
              ],
            ),
            Text(order.order.customerName),
            const SizedBox(height: 12),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.quantity}x ', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.menuItemName ?? '-'),
                          if (item.note != null && item.note!.isNotEmpty)
                            Text(
                              item.note!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref.read(orderControllerProvider.notifier).markServed(order.order.id),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Sudah Dihidangkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
