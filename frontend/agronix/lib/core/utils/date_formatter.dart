// lib/core/utils/date_formatter.dart

import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
  
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  
  static String formatDateTimeShort(DateTime date) {
    return DateFormat('dd/MM HH:mm').format(date);
  }
  
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'es_ES').format(date);
  }
  
  static String formatDayMonth(DateTime date) {
    return DateFormat('dd MMM', 'es_ES').format(date);
  }
  
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return 'Hace ${(difference.inDays / 365).floor()} años';
    } else if (difference.inDays > 30) {
      return 'Hace ${(difference.inDays / 30).floor()} meses';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minutos';
    } else {
      return 'Hace unos segundos';
    }
  }
}
