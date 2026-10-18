import 'daily_log.dart';

/// صفحة واحدة من قائمة السجلات اليومية (`GET /eld/daily-logs` الموحّد:
/// `page`/`size` + `pagination` في المغلف).
class DailyLogPage {
  final List<DailyLog> logs;
  final int page;
  final bool hasNext;
  final int? totalElements;
  final int? totalPages;

  const DailyLogPage({
    required this.logs,
    this.page = 0,
    this.hasNext = false,
    this.totalElements,
    this.totalPages,
  });

  static const DailyLogPage empty = DailyLogPage(logs: []);
}
