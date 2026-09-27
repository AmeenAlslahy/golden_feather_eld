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

/// Reads the transfer audit list. Returns null when the body is not a list,
/// so a missing list is an error rather than an empty official record.
List<TransferAuditRow>? parseTransferAudit(Object? raw) {
  final list = _asList(raw);
  if (list == null) return null;
  return list
      .whereType<Map>()
      .map((item) => _row(Map<String, dynamic>.from(item)))
      .where((row) => !row.isEmpty)
      .toList();
}

List<dynamic>? _asList(Object? raw) {
  if (raw is List) return raw;
  if (raw is! Map) return null;
  final map = Map<String, dynamic>.from(raw);
  for (final key in ['transfers', 'items', 'history', 'records', 'data', 'body']) {
    final value = map[key];
    if (value is List) return value;
    if (value is Map) {
      final nested = _asList(value);
      if (nested != null) return nested;
    }
  }
  // A bare `status` key is an envelope, not a transfer row.
  if (map.containsKey('channel') || map.containsKey('transferId')) {
    return [map];
  }
  return null;
}

TransferAuditRow _row(Map<String, dynamic> json) {
  return TransferAuditRow(
    channel: _text(json['channel']),
    recipient: _text(json['recipient'] ?? json['recipientEmail']),
    status: _text(json['status']),
    transferredAt: _text(json['transferredAt'] ?? json['createdAt']),
    message: _text(json['message']),
    period: _period(json['startDate'], json['endDate']),
    recordCount: _text(json['recordCount']),
  );
}

String _period(Object? start, Object? end) {
  final a = _text(start), b = _text(end);
  if (a.isEmpty && b.isEmpty) return '';
  if (a.isEmpty || b.isEmpty || a == b) return a.isEmpty ? b : a;
  return '$a – $b';
}

String _text(Object? value) {
  if (value == null) return '';
  return value.toString().trim();
}
