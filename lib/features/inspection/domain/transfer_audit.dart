/// صف سجل تدقيق التحويل (SRS 8.10) — نموذج صرف؛ قراءة جسم الخادم في
/// `data/mappers/inspection_mappers.dart`.
class TransferAuditRow {
  final String channel;
  final String recipient;
  final String status;
  final String transferredAt;
  final String message;

  /// SRS 8.10 — period covered and number of records (from
  /// `LogTransferResponse.startDate/endDate/recordCount`); empty when absent.
  final String period;
  final String recordCount;

  const TransferAuditRow({
    required this.channel,
    required this.recipient,
    required this.status,
    required this.transferredAt,
    required this.message,
    this.period = '',
    this.recordCount = '',
  });

  bool get isEmpty =>
      channel.isEmpty &&
      recipient.isEmpty &&
      status.isEmpty &&
      transferredAt.isEmpty &&
      message.isEmpty;
}
