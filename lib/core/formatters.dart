import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Formats amount to Vietnamese Dong standard: 150.000 đ
  static String formatCurrency(double amount) {
    return '${_currencyFormat.format(amount.round())} đ';
  }

  /// Formats date to dd/MM/yyyy
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formats time to HH:mm
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Formats date and time to dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Human-friendly relative date string
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    final diffDays = today.difference(target).inDays;
    if (diffDays == 0) {
      return 'Hôm nay (${formatTime(date)})';
    } else if (diffDays == 1) {
      return 'Hôm qua (${formatTime(date)})';
    } else if (diffDays < 7) {
      return '$diffDays ngày trước';
    } else {
      return formatDate(date);
    }
  }
}
