import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/utils/formatters.dart';
import '../models/expense_detail.dart';
import '../models/financial_summary.dart';
import '../models/ingredient.dart';
import '../models/order_detail.dart';

/// Builds printable PDF reports (and per-order receipts) and hands them to
/// the platform's print/share dialog via `printing` — works the same way on
/// Android, iOS, and web.
class PdfReportService {
  Future<void> printIngredients(List<Ingredient> ingredients) {
    return _printDocument(
      title: 'Laporan Stok Bahan Baku',
      subtitle: 'Dicetak ${AppFormat.dateLong(DateTime.now())}',
      buildContent: (context) => [
        pw.TableHelper.fromTextArray(
          headers: ['Nama Bahan', 'Satuan', 'Stok Saat Ini'],
          data: ingredients.map((i) => [i.name, i.unit, '${i.stockQuantity}']).toList(),
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
        ),
      ],
    );
  }

  Future<void> printFinancialSummary(FinancialSummary summary, DateTime from, DateTime to) {
    final dates = <DateTime>{
      ...summary.dailySales.map((e) => e.date),
      ...summary.dailyPurchases.map((e) => e.date),
      ...summary.dailyExpenses.map((e) => e.date),
    }.toList()
      ..sort();

    num amountFor(List<DailyTotal> list, DateTime date) => list
        .firstWhere((e) => e.date == date, orElse: () => DailyTotal(date: date, amount: 0))
        .amount;

    return _printDocument(
      title: 'Laporan Keuangan',
      subtitle: '${AppFormat.dateLong(from)} - ${AppFormat.dateLong(to)}',
      buildContent: (context) => [
        pw.TableHelper.fromTextArray(
          headerCount: 0,
          cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
          data: [
            ['Total Penjualan', AppFormat.rupiah(summary.totalSales)],
            ['Belanja Bahan Baku', AppFormat.rupiah(summary.totalIngredientPurchases)],
            ['Pengeluaran Lain', AppFormat.rupiah(summary.totalExpenses)],
            ['Laba Bersih', AppFormat.rupiah(summary.netProfit)],
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Tren Harian', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Tanggal', 'Penjualan', 'Belanja Bahan Baku', 'Pengeluaran Lain'],
          data: dates
              .map((date) => [
                    AppFormat.dateShort(date),
                    AppFormat.rupiah(amountFor(summary.dailySales, date)),
                    AppFormat.rupiah(amountFor(summary.dailyPurchases, date)),
                    AppFormat.rupiah(amountFor(summary.dailyExpenses, date)),
                  ])
              .toList(),
        ),
      ],
    );
  }

  Future<void> printExpenses(List<ExpenseDetail> expenses) {
    final rows = <List<String>>[];
    for (final expense in expenses) {
      for (final item in expense.items) {
        rows.add([
          AppFormat.dateShort(expense.batch.expenseDate),
          item.category,
          item.description ?? '-',
          AppFormat.rupiah(item.amount),
        ]);
      }
    }

    return _printDocument(
      title: 'Laporan Pengeluaran',
      subtitle: 'Dicetak ${AppFormat.dateLong(DateTime.now())}',
      buildContent: (context) => [
        pw.TableHelper.fromTextArray(
          headers: ['Tanggal', 'Kategori', 'Deskripsi', 'Nominal'],
          data: rows,
        ),
      ],
    );
  }

  Future<void> printSalesReport(List<OrderDetail> orders) {
    return _printDocument(
      title: 'Laporan Penjualan',
      subtitle: 'Dicetak ${AppFormat.dateLong(DateTime.now())}',
      buildContent: (context) => [
        pw.TableHelper.fromTextArray(
          headers: ['Tanggal', 'Pembeli', 'Meja', 'Item', 'Total', 'Bayar'],
          data: orders
              .map((order) => [
                    AppFormat.dateShort(order.order.orderDate),
                    order.order.customerName,
                    order.order.tableNumber,
                    order.items.map((i) => '${i.quantity}x ${i.menuItemName ?? '-'}').join(', '),
                    AppFormat.rupiah(order.totalAmount),
                    order.payment?.paymentMethod.toUpperCase() ?? '-',
                  ])
              .toList(),
        ),
      ],
    );
  }

  /// Small receipt-style PDF for a single paid order — sized like thermal
  /// receipt paper rather than a full A4 report page.
  Future<void> printReceipt(OrderDetail order) async {
    final doc = pw.Document();
    final pageFormat = PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text('Yansfood37', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(child: pw.Text('Struk Pembayaran', style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(height: 8),
            pw.Divider(),
            _receiptRow('Tanggal', AppFormat.dateLong(order.order.orderDate)),
            _receiptRow('Meja', order.order.tableNumber),
            _receiptRow('Pembeli', order.order.customerName),
            pw.Divider(),
            for (final item in order.items) ...[
              pw.Text('${item.quantity}x ${item.menuItemName ?? '-'}',
                  style: const pw.TextStyle(fontSize: 9)),
              if (item.note != null && item.note!.isNotEmpty)
                pw.Text('  (${item.note})', style: const pw.TextStyle(fontSize: 8)),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(AppFormat.rupiah(item.subtotal), style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
            pw.Divider(),
            _receiptRow('Total', AppFormat.rupiah(order.totalAmount), bold: true),
            if (order.payment != null) ...[
              _receiptRow('Metode Bayar', order.payment!.paymentMethod.toUpperCase()),
              if (order.payment!.paymentMethod == 'cash') ...[
                _receiptRow('Uang Diterima', AppFormat.rupiah(order.payment!.amountGiven)),
                _receiptRow('Kembalian', AppFormat.rupiah(order.payment!.changeAmount)),
              ],
            ],
            pw.SizedBox(height: 12),
            pw.Center(child: pw.Text('Terima kasih!', style: const pw.TextStyle(fontSize: 9))),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Struk Pesanan');
  }

  pw.Widget _receiptRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  Future<void> _printDocument({
    required String title,
    String? subtitle,
    required pw.BuildListCallback buildContent,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Yansfood37', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text(title, style: const pw.TextStyle(fontSize: 13)),
            if (subtitle != null)
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 8),
            pw.Divider(),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Dicetak ${AppFormat.dateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Halaman ${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
        build: buildContent,
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: title);
  }
}
