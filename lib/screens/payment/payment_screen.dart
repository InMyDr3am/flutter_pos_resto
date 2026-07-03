import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_detail.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.order});

  final OrderDetail order;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _method = PaymentMethod.cash;
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  num? get _amountGiven => num.tryParse(_amountController.text.trim());

  num get _change {
    final given = _amountGiven;
    if (given == null) return 0;
    final change = given - widget.order.totalAmount;
    return change > 0 ? change : 0;
  }

  bool get _canPay {
    if (_method == PaymentMethod.qris) return true;
    final given = _amountGiven;
    return given != null && given >= widget.order.totalAmount;
  }

  Future<void> _pay() async {
    final processedBy = ref.read(currentProfileProvider).value?.id;
    if (processedBy == null) return;

    final ok = await ref.read(paymentControllerProvider.notifier).pay(
          orderId: widget.order.order.id,
          method: _method,
          totalAmount: widget.order.totalAmount,
          amountGiven: _method == PaymentMethod.cash ? _amountGiven : null,
          processedBy: processedBy,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil.')),
      );
    } else {
      final error = ref.read(paymentControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran gagal: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isLoading = ref.watch(paymentControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${order.order.customerName} · Meja ${order.order.tableNumber}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(AppFormat.dateLong(order.order.orderDate)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item.quantity}x ${item.menuItemName ?? '-'}'),
                                if (item.note != null && item.note!.isNotEmpty)
                                  Text(
                                    item.note!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          Text(AppFormat.rupiah(item.subtotal)),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        AppFormat.rupiah(order.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Metode Pembayaran', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: PaymentMethod.cash,
                label: Text('Cash'),
                icon: Icon(Icons.payments_outlined),
              ),
              ButtonSegment(
                value: PaymentMethod.qris,
                label: Text('QRIS'),
                icon: Icon(Icons.qr_code_rounded),
              ),
            ],
            selected: {_method},
            onSelectionChanged: (selection) => setState(() => _method = selection.first),
          ),
          if (_method == PaymentMethod.cash) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Uang diterima', prefixText: 'Rp '),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian'),
                Text(
                  AppFormat.rupiah(_change),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_canPay && !isLoading) ? _pay : null,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Konfirmasi Pembayaran'),
          ),
        ],
      ),
    );
  }
}
