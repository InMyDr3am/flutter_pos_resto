/// Supabase table names, storage buckets, and role identifiers used across
/// the app. Centralized here so a rename only touches one file.
class SupaTables {
  SupaTables._();

  static const profiles = 'profiles';
  static const menuCategories = 'menu_categories';
  static const menuItems = 'menu_items';
  static const ingredients = 'ingredients';
  static const ingredientPurchases = 'ingredient_purchases';
  static const ingredientPurchaseItems = 'ingredient_purchase_items';
  static const expenses = 'expenses';
  static const expenseItems = 'expense_items';
  static const orders = 'orders';
  static const orderItems = 'order_items';
  static const payments = 'payments';
}

class SupaBuckets {
  SupaBuckets._();

  static const menuPhotos = 'menu-photos';
}

/// Mirrors the `role` check constraint on the `profiles` table.
class AppRole {
  AppRole._();

  static const owner = 'owner';
  static const kasir = 'kasir';
  static const karyawan = 'karyawan';

  static const all = [owner, kasir, karyawan];

  static String label(String role) {
    switch (role) {
      case owner:
        return 'Pemilik';
      case kasir:
        return 'Kasir';
      case karyawan:
        return 'Karyawan';
      default:
        return role;
    }
  }
}

/// Mirrors the `status` check constraint on the `orders` table.
class OrderStatus {
  OrderStatus._();

  static const onProcess = 'on_process';
  static const served = 'served';
  static const paid = 'paid';
  static const cancelled = 'cancelled';
}

/// Mirrors the `payment_method` check constraint on the `payments` table.
class PaymentMethod {
  PaymentMethod._();

  static const cash = 'cash';
  static const qris = 'qris';
}
