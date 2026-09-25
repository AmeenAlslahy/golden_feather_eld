import 'entities/dvir_report.dart';

class DvirListSummary {
  final int total;
  final int openDefects;
  final int signed;
  final int outOfService;

  const DvirListSummary({
    required this.total,
    required this.openDefects,
    required this.signed,
    required this.outOfService,
  });
}

/// Counts from the list the driver already loaded. No invented reports.
DvirListSummary summarizeDvirReports(List<DvirReport> reports) {
  var openDefects = 0;
  var signed = 0;
  var outOfService = 0;
  for (final report in reports) {
    if (report.hasDefects && !report.certified) openDefects++;
    if (report.certified || report.signature != null) signed++;
    if (report.outOfService) outOfService++;
  }
  return DvirListSummary(
    total: reports.length,
    openDefects: openDefects,
    signed: signed,
    outOfService: outOfService,
  );
}
