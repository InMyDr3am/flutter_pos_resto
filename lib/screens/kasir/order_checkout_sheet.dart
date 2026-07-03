import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

/// Final step of the cashier flow: table number, customer name, order date,
/// and a review of the cart (with per-item notes) before submitting.
class OrderCheckoutSheet extends ConsumerStatefulWidget {
  const OrderCheckoutSheet({super.key});

  @override
  ConsumerState<OrderCheckoutSheet> createState() => _OrderCheckoutSheetState();
}

class _OrderCheckoutSheetState extends ConsumerState<OrderCheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tableController;
  late final TextEditingController _customerController;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(cartProvider);
    _tableController = TextEditingController(text: cart.tableNumber);
    _customerController = TextEditingController(text: cart.customerName);
  }

  @override
  void dispose() {
    _tableController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final cart = ref.read(cartProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: cart.orderDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) ref.read(cartProvider.notifier).setOrderDate(picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(cartProvider.notifier).setTableNumber(_tableController.text.trim());
    ref.read(cartProvider.notifier).setCustomerName(_customerController.text.trim());

    final createdBy = ref.read(currentProfileProvider).value?.id;
    if (createdBy == null) return;

    final ok = await ref.read(orderControllerProvider.notifier).submitOrder(createdBy);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dibuat.')),
      );
    } else {
      final error = ref.read(orderControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat pesanan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isLoading = ref.watch(orderControllerProvider).isLoading;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text(
                'Ringkasan Pesanan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              for (final line in cart.lines) _CartLineTile(menuItemId: line.menuItem.id),
              const Divider(height: 32),
              TextFormField(
                controller: _tableController,
                decoration: const InputDecoration(labelText: 'Nomor meja'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nomor meja wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'Nama pembeli'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pembeli wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal pesanan'),
                subtitle: Text(AppFormat.dateLong(cart.orderDate)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(
                    AppFormat.rupiah(cart.total),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Buat Pesanan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.menuItemId});

  final String menuItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = ref.watch(cartProvider.select((c) {
      for (final l in c.lines) {
        if (l.menuItem.id == menuItemId) return l;
      }
      return null;
    }));
    if (line == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${line.quantity}x ${line.menuItem.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: line.note,
                  decoration: const InputDecoration(
                    hintText: 'Catatan (opsional)',
                    isDense: true,
                  ),
                  onChanged: (value) => ref.read(cartProvider.notifier).setNote(menuItemId, value),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(AppFormat.rupiah(line.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
