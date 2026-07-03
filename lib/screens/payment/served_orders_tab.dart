import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/order_detail.dart';
import '../../providers/order_provider.dart';
import 'payment_screen.dart';

/// Orders that are `served` and waiting to be paid — the cashier's payment queue.
class ServedOrdersTab extends ConsumerWidget {
  const ServedOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(servedOrdersProvider);

    return AsyncValueWidget(
      value: ordersAsync,
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada pesanan untuk dibayar',
            message: 'Pesanan yang sudah dihidangkan akan muncul di sini.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _ServedOrderCard(order: orders[index]),
        );
      },
    );
  }
}

class _ServedOrderCard extends ConsumerWidget {
  const _ServedOrderCard({required this.order});

  final OrderDetail order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PaymentScreen(order: order)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.order.customerName} · Meja ${order.order.tableNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('${order.items.length} item · ${AppFormat.dateLong(order.order.orderDate)}'),
                  ],
                ),
              ),
              Text(
                AppFormat.rupiah(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.error),
                tooltip: 'Batalkan pesanan',
                onPressed: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Batalkan pesanan?',
                    message:
                        'Pesanan "${order.order.customerName}" Meja ${order.order.tableNumber} akan dibatalkan.',
                    confirmLabel: 'Batalkan',
                  );
                  if (confirmed) {
                    await ref.read(orderControllerProvider.notifier).cancelOrder(order.order.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
