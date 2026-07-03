import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/accent_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';

class _DashboardItem {
  const _DashboardItem(this.icon, this.label, this.route, this.color);
  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

const _operationalItems = [
  _DashboardItem(Icons.point_of_sale_outlined, 'Buat Pesanan', '/kasir', AppAccent.kasir),
  _DashboardItem(Icons.soup_kitchen_outlined, 'Dapur', '/kitchen', AppAccent.kitchen),
  _DashboardItem(Icons.restaurant_menu_rounded, 'Kelola Menu', '/owner/menu', AppAccent.menu),
  _DashboardItem(Icons.egg_alt_outlined, 'Bahan Baku', '/owner/ingredients', AppAccent.ingredients),
  _DashboardItem(
    Icons.shopping_cart_outlined,
    'Belanja Bahan Baku',
    '/owner/purchases',
    AppAccent.purchases,
  ),
  _DashboardItem(Icons.receipt_long_outlined, 'Pengeluaran', '/owner/expenses', AppAccent.expenses),
];

const _insightItems = [
  _DashboardItem(
    Icons.trending_up_rounded,
    'Laporan Penjualan',
    '/owner/sales-report',
    AppAccent.salesReport,
  ),
  _DashboardItem(
    Icons.insert_chart_outlined_rounded,
    'Laporan Keuangan',
    '/owner/financial-report',
    AppAccent.financialReport,
  ),
  _DashboardItem(Icons.badge_outlined, 'Kelola Karyawan', '/owner/employees', AppAccent.employees),
];

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = ref.watch(currentProfileProvider).value;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 172,
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Keluar',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, const Color(0xFF14503D)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          AppFormat.dateLong(DateTime.now()),
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Halo, ${profile?.fullName ?? 'Pemilik'} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pantau dan kelola seluruh operasional resto Anda',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Operasional',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _DashboardGrid(items: _operationalItems),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Laporan & Tim',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _DashboardGrid(items: _insightItems),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.items});

  final List<_DashboardItem> items;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.15,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(item.route),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}
