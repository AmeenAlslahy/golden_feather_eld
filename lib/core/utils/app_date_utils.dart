class AppDateUtils {
  /// Format a DateTime into 'YYYY-MM-DD' string for storage keys
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Extract date string from an ISO string, defaults to today's date if parsing fails
  static String extractDateStr(String? isoString) {
    if (isoString == null) return formatDate(DateTime.now());
    try {
      return formatDate(DateTime.parse(isoString));
    } catch (_) {
      return formatDate(DateTime.now());
    }
  }
}
