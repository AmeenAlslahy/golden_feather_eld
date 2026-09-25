class TransferAuditRow {
  final String channel;
  final String recipient;
  final String status;
  final String transferredAt;
  final String message;

  const TransferAuditRow({
    required this.channel,
    required this.recipient,
    required this.status,
    required this.transferredAt,
    required this.message,
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
  );
}

String _text(Object? value) {
  if (value == null) return '';
  return value.toString().trim();
}
