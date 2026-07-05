import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/formatters.dart';
import '../models/expense_detail.dart';
import '../models/financial_summary.dart';
import '../models/ingredient.dart';
import '../models/order_detail.dart';

/// Builds `.xlsx` files for the app's reports and shares them via the OS
/// share sheet (which on mobile includes "Save to Drive" / WhatsApp / email,
/// and on web falls back to a direct download) — the file opens directly in
/// Google Sheets or Excel without any Google account wiring in the app.
class ExcelExportService {
  Future<void> exportIngredients(List<Ingredient> ingredients) async {
    final excel = Excel.createExcel();
    final sheet = excel['Stok Bahan Baku'];
    excel.setDefaultSheet('Stok Bahan Baku');

    sheet.appendRow([
      TextCellValue('Nama Bahan'),
      TextCellValue('Satuan'),
      TextCellValue('Stok Saat Ini'),
    ]);
    for (final ingredient in ingredients) {
      sheet.appendRow([
        TextCellValue(ingredient.name),
        TextCellValue(ingredient.unit),
        DoubleCellValue(ingredient.stockQuantity.toDouble()),
      ]);
    }

    await _share(excel, 'Stok_Bahan_Baku');
  }

  Future<void> exportFinancialSummary(
    FinancialSummary summary,
    DateTime from,
    DateTime to,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Keuangan'];
    excel.setDefaultSheet('Laporan Keuangan');

    sheet.appendRow([
      TextCellValue('Periode'),
      TextCellValue('${AppFormat.dateLong(from)} - ${AppFormat.dateLong(to)}'),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Total Penjualan'), DoubleCellValue(summary.totalSales.toDouble())]);
    sheet.appendRow([
      TextCellValue('Belanja Bahan Baku'),
      DoubleCellValue(summary.totalIngredientPurchases.toDouble()),
    ]);
    sheet.appendRow([
      TextCellValue('Pengeluaran Lain'),
      DoubleCellValue(summary.totalExpenses.toDouble()),
    ]);
    sheet.appendRow([TextCellValue('Laba Bersih'), DoubleCellValue(summary.netProfit.toDouble())]);
    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Penjualan'),
      TextCellValue('Belanja Bahan Baku'),
      TextCellValue('Pengeluaran Lain'),
    ]);

    final dates = <DateTime>{
      ...summary.dailySales.map((e) => e.date),
      ...summary.dailyPurchases.map((e) => e.date),
      ...summary.dailyExpenses.map((e) => e.date),
    }.toList()
      ..sort();

    num amountFor(List<DailyTotal> list, DateTime date) =>
        list.firstWhere((e) => e.date == date, orElse: () => DailyTotal(date: date, amount: 0)).amount;

    for (final date in dates) {
      sheet.appendRow([
        TextCellValue(AppFormat.dateShort(date)),
        DoubleCellValue(amountFor(summary.dailySales, date).toDouble()),
        DoubleCellValue(amountFor(summary.dailyPurchases, date).toDouble()),
        DoubleCellValue(amountFor(summary.dailyExpenses, date).toDouble()),
      ]);
    }

    await _share(excel, 'Laporan_Keuangan');
  }

  Future<void> exportExpenses(List<ExpenseDetail> expenses) async {
    final excel = Excel.createExcel();
    final sheet = excel['Pengeluaran'];
    excel.setDefaultSheet('Pengeluaran');

    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Kategori'),
      TextCellValue('Deskripsi'),
      TextCellValue('Nominal'),
    ]);
    for (final expense in expenses) {
      for (final item in expense.items) {
        sheet.appendRow([
          TextCellValue(AppFormat.dateShort(expense.batch.expenseDate)),
          TextCellValue(item.category),
          TextCellValue(item.description ?? ''),
          DoubleCellValue(item.amount.toDouble()),
        ]);
      }
    }

    await _share(excel, 'Pengeluaran');
  }

  Future<void> exportSalesReport(List<OrderDetail> orders) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Penjualan'];
    excel.setDefaultSheet('Laporan Penjualan');

    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Pembeli'),
      TextCellValue('No. Meja'),
      TextCellValue('Item'),
      TextCellValue('Total'),
      TextCellValue('Metode Bayar'),
      TextCellValue('Uang Diterima'),
      TextCellValue('Kembalian'),
    ]);
    for (final order in orders) {
      final itemsSummary = order.items.map((i) => '${i.quantity}x ${i.menuItemName ?? '-'}').join(', ');
      sheet.appendRow([
        TextCellValue(AppFormat.dateShort(order.order.orderDate)),
        TextCellValue(order.order.customerName),
        TextCellValue(order.order.tableNumber),
        TextCellValue(itemsSummary),
        DoubleCellValue(order.totalAmount.toDouble()),
        TextCellValue(order.payment?.paymentMethod.toUpperCase() ?? '-'),
        DoubleCellValue((order.payment?.amountGiven ?? 0).toDouble()),
        DoubleCellValue((order.payment?.changeAmount ?? 0).toDouble()),
      ]);
    }

    await _share(excel, 'Laporan_Penjualan');
  }

  Future<void> _share(Excel excel, String baseFileName) async {
    excel.delete('Sheet1');
    final bytes = excel.save();
    if (bytes == null) throw StateError('Gagal membuat file Excel.');

    final fileName =
        '${baseFileName}_${DateTime.now().toIso8601String().split('T').first}.xlsx';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: [fileName],
      ),
    );
  }
}
