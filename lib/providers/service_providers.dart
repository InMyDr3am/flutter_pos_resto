import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/employee_service.dart';
import '../services/expense_service.dart';
import '../services/ingredient_service.dart';
import '../services/menu_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/purchase_service.dart';
import '../services/report_service.dart';

/// One `Provider` per repository/service. Screens never talk to Supabase
/// directly — everything goes through these.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final menuServiceProvider = Provider<MenuService>((ref) => MenuService());
final ingredientServiceProvider = Provider<IngredientService>((ref) => IngredientService());
final purchaseServiceProvider = Provider<PurchaseService>((ref) => PurchaseService());
final expenseServiceProvider = Provider<ExpenseService>((ref) => ExpenseService());
final orderServiceProvider = Provider<OrderService>((ref) => OrderService());
final paymentServiceProvider = Provider<PaymentService>((ref) => PaymentService());
final reportServiceProvider = Provider<ReportService>((ref) => ReportService());
final employeeServiceProvider = Provider<EmployeeService>((ref) => EmployeeService());
