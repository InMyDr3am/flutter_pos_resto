import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/order_detail.dart';
import '../../providers/order_provider.dart';
import 'edit_order_screen.dart';

/// Orders still `on_process` — lets the cashier fix mistakes (edit items,
/// table, customer, date) or cancel before the kitchen finishes plating it.
class ActiveOrdersTab extends ConsumerWidget {
  const ActiveOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(kitchenOrdersProvider);

    return AsyncValueWidget(
      value: ordersAsync,
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyState(
            icon: Icons.pending_actions_outlined,
            title: 'Belum ada pesanan aktif',
            message: 'Pesanan yang masih diproses dapur akan muncul di sini.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _ActiveOrderCard(order: orders[index]),
        );
      },
    );
  }
}

class _ActiveOrderCard extends ConsumerWidget {
  const _ActiveOrderCard({required this.order});

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.order.customerName} · Meja ${order.order.tableNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text('${order.items.length} item · ${AppFormat.dateLong(order.order.orderDate)}'),
                    ],
                  ),
                ),
                Text(
                  AppFormat.rupiah(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Guards against a double/ghost tap firing this twice
                      // in quick succession, which pushes two overlapping
                      // routes and stalls the Navigator's transition build.
                      if (ModalRoute.of(context)?.isCurrent != true) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EditOrderScreen(order: order)),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              title: 'Batalkan pesanan?',
                              message:
                                  'Pesanan "${order.order.customerName}" Meja ${order.order.tableNumber} akan dibatalkan.',
                              confirmLabel: 'Batalkan',
                            );
                            if (confirmed) {
                              await ref
                                  .read(orderControllerProvider.notifier)
                                  .cancelOrder(order.order.id);
                            }
                          },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Batalkan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
