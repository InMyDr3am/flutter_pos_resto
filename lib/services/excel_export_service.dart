import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/formatters.dart';
import '../models/expense_detail.dart';
import '../models/financial_summary.dart';
import '../models/ingredient.dart';
import '../models/order_detail.dart';
import '../models/purchase_detail.dart';

/// Builds `.xlsx` files for the app's reports and shares them via the OS
/// share sheet (which on mobile includes "Save to Drive" / WhatsApp / email,
/// and on web falls back to a direct download) — the file opens directly in
/// Google Sheets or Excel without any Google account wiring in the app.
///
/// Every sheet gets the same "Yansfood37" branded banner (title + what the
/// data represents) followed by a bordered, colored-header table, instead of
/// a bare data dump.
class ExcelExportService {
  static const _brandColor = '#1E7A5F';
  static const _borderColor = '#BDBDBD';

  static final _titleStyle = CellStyle(
    bold: true,
    fontSize: 18,
    fontColorHex: ExcelColor.fromHexString(_brandColor),
    horizontalAlign: HorizontalAlign.Center,
  );

  static final _subtitleStyle = CellStyle(
    bold: true,
    fontSize: 12,
    horizontalAlign: HorizontalAlign.Center,
  );

  static final _infoStyle = CellStyle(
    italic: true,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString('#616161'),
    horizontalAlign: HorizontalAlign.Center,
  );

  static final _headerStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString(_brandColor),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString(_borderColor)),
    rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString(_borderColor)),
    topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString(_borderColor)),
    bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString(_borderColor)),
  );

  static CellStyle _dataStyle({bool bold = false, HorizontalAlign align = HorizontalAlign.Left}) => CellStyle(
        bold: bold,
        horizontalAlign: align,
        leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString(_borderColor)),
        rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString(_borderColor)),
        topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString(_borderColor)),
        bottomBorder:
            Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString(_borderColor)),
      );

  /// Writes the "Yansfood37" banner + report title + description across the
  /// first 3 rows (row 3 is left blank as spacing) and returns the index of
  /// the next free row.
  int _writeBanner(Sheet sheet, String title, String subtitle, int columnCount) {
    final lastCol = columnCount - 1;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: lastCol, rowIndex: 0),
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      TextCellValue('Yansfood37'),
      cellStyle: _titleStyle,
    );

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: lastCol, rowIndex: 1),
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      TextCellValue(title),
      cellStyle: _subtitleStyle,
    );

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      CellIndex.indexByColumnRow(columnIndex: lastCol, rowIndex: 2),
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2),
      TextCellValue(subtitle),
      cellStyle: _infoStyle,
    );

    return 4;
  }

  int _writeHeaderRow(Sheet sheet, int rowIndex, List<String> headers, {List<double>? widths}) {
    for (var c = 0; c < headers.length; c++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex),
        TextCellValue(headers[c]),
        cellStyle: _headerStyle,
      );
      sheet.setColumnWidth(c, widths != null && c < widths.length ? widths[c] : 20);
    }
    return rowIndex + 1;
  }

  int _writeDataRow(Sheet sheet, int rowIndex, List<CellValue> values, {bool bold = false}) {
    for (var c = 0; c < values.length; c++) {
      final align = values[c] is TextCellValue ? HorizontalAlign.Left : HorizontalAlign.Right;
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex),
        values[c],
        cellStyle: _dataStyle(bold: bold, align: align),
      );
    }
    return rowIndex + 1;
  }

  Future<void> exportIngredients(List<Ingredient> ingredients) async {
    final excel = Excel.createExcel();
    final sheet = excel['Stok Bahan Baku'];
    excel.setDefaultSheet('Stok Bahan Baku');

    var row = _writeBanner(
      sheet,
      'Laporan Stok Bahan Baku',
      'Data stok bahan baku saat ini · Dicetak ${AppFormat.dateLong(DateTime.now())} · ${ingredients.length} bahan',
      3,
    );
    row = _writeHeaderRow(sheet, row, ['Nama Bahan', 'Satuan', 'Stok Saat Ini'], widths: [28, 14, 16]);
    for (final ingredient in ingredients) {
      row = _writeDataRow(sheet, row, [
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

    var row = _writeBanner(
      sheet,
      'Laporan Keuangan',
      'Ringkasan keuangan periode ${AppFormat.dateLong(from)} - ${AppFormat.dateLong(to)}',
      4,
    );

    row = _writeDataRow(sheet, row, [TextCellValue('Total Penjualan'), DoubleCellValue(summary.totalSales.toDouble())], bold: true);
    row = _writeDataRow(
      sheet,
      row,
      [TextCellValue('Belanja Bahan Baku'), DoubleCellValue(summary.totalIngredientPurchases.toDouble())],
      bold: true,
    );
    row = _writeDataRow(
      sheet,
      row,
      [TextCellValue('Pengeluaran Lain'), DoubleCellValue(summary.totalExpenses.toDouble())],
      bold: true,
    );
    row = _writeDataRow(sheet, row, [TextCellValue('Laba Bersih'), DoubleCellValue(summary.netProfit.toDouble())], bold: true);
    row += 1;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
    );
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      TextCellValue('Tren Harian'),
      cellStyle: _subtitleStyle,
    );
    row += 1;

    row = _writeHeaderRow(
      sheet,
      row,
      ['Tanggal', 'Penjualan', 'Belanja Bahan Baku', 'Pengeluaran Lain'],
      widths: [14, 18, 20, 18],
    );

    final dates = <DateTime>{
      ...summary.dailySales.map((e) => e.date),
      ...summary.dailyPurchases.map((e) => e.date),
      ...summary.dailyExpenses.map((e) => e.date),
    }.toList()
      ..sort();

    num amountFor(List<DailyTotal> list, DateTime date) =>
        list.firstWhere((e) => e.date == date, orElse: () => DailyTotal(date: date, amount: 0)).amount;

    for (final date in dates) {
      row = _writeDataRow(sheet, row, [
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

    final itemCount = expenses.fold<int>(0, (sum, e) => sum + e.items.length);
    var row = _writeBanner(
      sheet,
      'Laporan Pengeluaran',
      'Data pengeluaran lain di luar belanja bahan baku · Dicetak ${AppFormat.dateLong(DateTime.now())} · $itemCount item',
      4,
    );
    row = _writeHeaderRow(sheet, row, ['Tanggal', 'Kategori', 'Deskripsi', 'Nominal'], widths: [14, 18, 30, 16]);
    for (final expense in expenses) {
      for (final item in expense.items) {
        row = _writeDataRow(sheet, row, [
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

    var row = _writeBanner(
      sheet,
      'Laporan Penjualan',
      'Data transaksi penjualan yang sudah lunas · Dicetak ${AppFormat.dateLong(DateTime.now())} · ${orders.length} transaksi',
      8,
    );
    row = _writeHeaderRow(
      sheet,
      row,
      ['Tanggal', 'Pembeli', 'No. Meja', 'Item', 'Total', 'Metode Bayar', 'Uang Diterima', 'Kembalian'],
      widths: [14, 18, 10, 36, 16, 14, 16, 14],
    );
    for (final order in orders) {
      final itemsSummary = order.items.map((i) => '${i.quantity}x ${i.menuItemName ?? '-'}').join(', ');
      row = _writeDataRow(sheet, row, [
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

  Future<void> exportPurchases(List<PurchaseDetail> purchases) async {
    final excel = Excel.createExcel();
    final sheet = excel['Belanja Bahan Baku'];
    excel.setDefaultSheet('Belanja Bahan Baku');

    final itemCount = purchases.fold<int>(0, (sum, p) => sum + p.items.length);
    var row = _writeBanner(
      sheet,
      'Laporan Belanja Bahan Baku',
      'Data riwayat belanja bahan baku · Dicetak ${AppFormat.dateLong(DateTime.now())} · $itemCount item',
      6,
    );
    row = _writeHeaderRow(
      sheet,
      row,
      ['Tanggal', 'Bahan Baku', 'Jumlah', 'Satuan', 'Harga Satuan', 'Subtotal'],
      widths: [14, 24, 12, 12, 16, 16],
    );
    for (final purchase in purchases) {
      for (final item in purchase.items) {
        row = _writeDataRow(sheet, row, [
          TextCellValue(AppFormat.dateShort(purchase.batch.purchaseDate)),
          TextCellValue(item.ingredientName ?? '-'),
          DoubleCellValue(item.quantity.toDouble()),
          TextCellValue(item.ingredientUnit ?? ''),
          DoubleCellValue(item.unitPrice.toDouble()),
          DoubleCellValue(item.totalPrice.toDouble()),
        ]);
      }
    }

    await _share(excel, 'Belanja_Bahan_Baku');
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
