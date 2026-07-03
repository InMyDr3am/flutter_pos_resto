import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../screens/payment/served_orders_tab.dart';
import '../../screens/reports/sales_report_screen.dart';
import 'new_order_tab.dart';
import 'order_checkout_sheet.dart';

const _titles = ['Buat Pesanan', 'Pembayaran', 'Laporan Penjualan'];

class KasirHomeScreen extends ConsumerStatefulWidget {
  const KasirHomeScreen({super.key});

  @override
  ConsumerState<KasirHomeScreen> createState() => _KasirHomeScreenState();
}

class _KasirHomeScreenState extends ConsumerState<KasirHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          NewOrderTab(),
          ServedOrdersTab(),
          SalesReportScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_index == 0 && cart.lines.isNotEmpty)
              Material(
                color: Theme.of(context).colorScheme.primary,
                child: InkWell(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const OrderCheckoutSheet(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cart.itemCount} item · ${AppFormat.rupiah(cart.total)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const Row(
                          children: [
                            Text('Lanjutkan', style: TextStyle(color: Colors.white)),
                            Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.add_shopping_cart_outlined), label: 'Pesanan'),
                NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Bayar'),
                NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Laporan'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
