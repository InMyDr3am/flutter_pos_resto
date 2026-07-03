import 'package:intl/intl.dart';

/// Rupiah / Indonesian date formatting helpers.
///
/// `initializeDateFormatting('id_ID')` must run once before these are used
/// (done in `main.dart`), otherwise `DateFormat` throws for the `id_ID` locale.
class AppFormat {
  AppFormat._();

  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _dateLong = DateFormat('d MMMM yyyy', 'id_ID');
  static final _dateShort = DateFormat('dd/MM/yyyy', 'id_ID');
  static final _dateTime = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
  static final _time = DateFormat('HH:mm', 'id_ID');

  static String rupiah(num? value) => _rupiah.format(value ?? 0);

  static String dateLong(DateTime date) => _dateLong.format(date);

  static String dateShort(DateTime date) => _dateShort.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date.toLocal());

  static String time(DateTime date) => _time.format(date.toLocal());
}
