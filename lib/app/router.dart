import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/service_providers.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/employees/employee_list_screen.dart';
import '../screens/expenses/expense_list_screen.dart';
import '../screens/ingredients/ingredient_list_screen.dart';
import '../screens/kasir/kasir_home_screen.dart';
import '../screens/kitchen/kitchen_screen.dart';
import '../screens/menu/menu_list_screen.dart';
import '../screens/owner/owner_dashboard_screen.dart';
import '../screens/purchases/purchase_list_screen.dart';
import '../screens/reports/financial_report_screen.dart';
import '../screens/reports/sales_report_screen.dart';

/// Notifies [GoRouter] to re-run `redirect` whenever auth state or the
/// signed-in profile changes, without recreating the router (which would
/// otherwise wipe the navigation stack).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
    ref.listen(currentProfileProvider, (_, _) => notifyListeners());
  }
}

String _homeForRole(String role) => switch (role) {
      AppRole.owner => '/owner',
      AppRole.kasir => '/kasir',
      AppRole.karyawan => '/kitchen',
      _ => '/login',
    };

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onSplash = location == '/splash';
      final onLogin = location == '/login';

      final session = ref.read(authServiceProvider).currentUser;

      if (session == null) {
        return onLogin ? null : '/login';
      }

      final profileAsync = ref.read(currentProfileProvider);
      if (profileAsync.isLoading) {
        return onSplash ? null : null;
      }

      final profile = profileAsync.value;
      if (profile == null) {
        // Session exists but no profile row (or fetch failed) — bounce to
        // login rather than stranding the user on a blank screen.
        return onLogin ? null : '/login';
      }

      final home = _homeForRole(profile.role);
      if (onSplash || onLogin) return home;

      // Owner has full access to every screen (kasir + kitchen included) so
      // they can monitor and step into any process; other roles stay
      // confined to their own section.
      if (profile.role == AppRole.owner) return null;
      if (!location.startsWith(home)) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Owner
      GoRoute(path: '/owner', builder: (context, state) => const OwnerDashboardScreen()),
      GoRoute(path: '/owner/menu', builder: (context, state) => const MenuListScreen()),
      GoRoute(
        path: '/owner/ingredients',
        builder: (context, state) => const IngredientListScreen(),
      ),
      GoRoute(
        path: '/owner/purchases',
        builder: (context, state) => const PurchaseListScreen(),
      ),
      GoRoute(path: '/owner/expenses', builder: (context, state) => const ExpenseListScreen()),
      GoRoute(
        path: '/owner/sales-report',
        builder: (context, state) => const SalesReportScreen(),
      ),
      GoRoute(
        path: '/owner/financial-report',
        builder: (context, state) => const FinancialReportScreen(),
      ),
      GoRoute(
        path: '/owner/employees',
        builder: (context, state) => const EmployeeListScreen(),
      ),

      // Kasir
      GoRoute(path: '/kasir', builder: (context, state) => const KasirHomeScreen()),

      // Karyawan
      GoRoute(path: '/kitchen', builder: (context, state) => const KitchenScreen()),
    ],
  );
});
