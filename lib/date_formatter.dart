import 'package:intl/intl.dart';

class DateFormatter {
  /// Format long : 24 octobre 2025 à 14:30
  static String formatLong(DateTime? date) {
    if (date == null) return 'Date inconnue';
    final formatter = DateFormat('d MMMM y à HH:mm', 'fr_FR');
    return formatter.format(date);
  }

  /// Format court : 24/10/2025
  static String formatShort(DateTime? date) {
    if (date == null) return 'Date inconnue';
    final formatter = DateFormat('dd/MM/yyyy', 'fr_FR');
    return formatter.format(date);
  }

  /// Heure seule : 14:30
  static String formatHeure(DateTime? date) {
    if (date == null) return '';
    final formatter = DateFormat('HH:mm', 'fr_FR');
    return formatter.format(date);
  }
}
