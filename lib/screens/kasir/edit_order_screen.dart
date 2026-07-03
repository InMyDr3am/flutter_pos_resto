import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../models/menu_item.dart';
import '../../models/order_detail.dart';
import '../../providers/edit_order_draft_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';

/// Edits an `on_process` order's table/customer/date and its full item list.
class EditOrderScreen extends ConsumerStatefulWidget {
  const EditOrderScreen({super.key, required this.order});

  final OrderDetail order;

  @override
  ConsumerState<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends ConsumerState<EditOrderScreen> {
  late final TextEditingController _tableController;
  late final TextEditingController _customerController;
  final _searchController = TextEditingController();
  bool _saving = false;
  bool _showAddMenu = false;

  @override
  void initState() {
    super.initState();
    // Deferred to a post-frame callback: setting provider state synchronously
    // (or even via Future.microtask, which can still land inside the same
    // build pass) inside initState() — while this very widget is still being
    // mounted — trips Riverpod's "modified a provider during build" guard.
    // addPostFrameCallback guarantees the frame has fully finished first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(editOrderDraftProvider.notifier).loadFrom(widget.order);
    });
    _tableController = TextEditingController(text: widget.order.order.tableNumber);
    _customerController = TextEditingController(text: widget.order.order.customerName);
  }

  @override
  void dispose() {
    _tableController.dispose();
    _customerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final draft = ref.read(editOrderDraftProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.orderDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) ref.read(editOrderDraftProvider.notifier).setOrderDate(picked);
  }

  Future<void> _save() async {
    ref.read(editOrderDraftProvider.notifier).setTableNumber(_tableController.text.trim());
    ref.read(editOrderDraftProvider.notifier).setCustomerName(_customerController.text.trim());

    setState(() => _saving = true);
    final ok = await ref
        .read(orderControllerProvider.notifier)
        .submitOrderEdit(widget.order.order.id);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil diperbarui.')),
      );
    } else {
      final error = ref.read(orderControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: ${error ?? 'lengkapi data pesanan'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(editOrderDraftProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pesanan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _tableController,
            decoration: const InputDecoration(labelText: 'Nomor meja'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _customerController,
            decoration: const InputDecoration(labelText: 'Nama pembeli'),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tanggal pesanan'),
            subtitle: Text(AppFormat.dateLong(draft.orderDate)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const Divider(height: 32),
          Text('Item Pesanan', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (draft.lines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada item. Tambahkan menu di bawah.'),
            )
          else
            for (final line in draft.lines)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              line.menuItem.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () => ref
                                .read(editOrderDraftProvider.notifier)
                                .decrement(line.menuItem.id),
                          ),
                          Text('${line.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () =>
                                ref.read(editOrderDraftProvider.notifier).increment(line.menuItem),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => ref
                                .read(editOrderDraftProvider.notifier)
                                .removeLine(line.menuItem.id),
                          ),
                        ],
                      ),
                      TextFormField(
                        initialValue: line.note,
                        decoration: const InputDecoration(hintText: 'Catatan (opsional)', isDense: true),
                        onChanged: (value) =>
                            ref.read(editOrderDraftProvider.notifier).setNote(line.menuItem.id, value),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showAddMenu = !_showAddMenu),
            icon: Icon(_showAddMenu ? Icons.expand_less_rounded : Icons.add),
            label: const Text('Tambah Menu'),
          ),
          if (_showAddMenu) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari menu...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            _AddMenuList(
              query: _searchController.text,
              onAdd: (item) => ref.read(editOrderDraftProvider.notifier).increment(item),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(
                AppFormat.rupiah(draft.total),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_saving || !draft.isValid) ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}

class _AddMenuList extends ConsumerWidget {
  const _AddMenuList({required this.query, required this.onAdd});

  final String query;
  final void Function(MenuItem item) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allMenuItemsProvider);

    return AsyncValueWidget(
      value: itemsAsync,
      data: (items) {
        final available = items.where((i) {
          if (!i.isAvailable) return false;
          if (query.trim().isEmpty) return true;
          return i.name.toLowerCase().contains(query.trim().toLowerCase());
        }).toList();

        if (available.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Menu tidak ditemukan.'),
          );
        }

        // Deliberately not wrapped in its own scrollable: this list already
        // lives inside the screen's outer ListView, and nesting a second
        // independently-scrolling list here caused the gesture arena to
        // stall (observed as a 10s ANR on some devices).
        return Column(
          children: [
            for (final item in available)
              ListTile(
                dense: true,
                title: Text(item.name),
                subtitle: Text(AppFormat.rupiah(item.price)),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onAdd(item),
                ),
              ),
          ],
        );
      },
    );
  }
}
