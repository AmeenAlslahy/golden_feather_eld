import '../../domain/inspection_transfer.dart';
import '../../domain/transfer_audit.dart';

/// قراءة أجسام الخادم إلى نماذج الـ domain — كل التحليل هنا في طبقة
/// البيانات؛ الـ domain يحتفظ بالنماذج الصرفة فقط.

/// Reads the server transfer body. A missing status is not a local file.
TransferOutcome readTransferOutcome(Map<String, dynamic> json) {
  final message = json['message'];
  final status = json['status'];
  final statusText = status is String ? status.trim() : '';
  final messageText = message is String ? message.trim() : '';
  // Live contract: the server answers 'PENDING' for an accepted transfer
  // that is queued, so acceptance is deny-listed, not whitelisted. A
  // missing status (HTTP 200 + message only) is also an acceptance.
  final failed = const {'failed', 'error', 'rejected', 'denied'}
      .contains(statusText.toLowerCase());
  final text = messageText.isNotEmpty
      ? messageText
      : statusText.isNotEmpty
          ? statusText
          : 'The server accepted the transfer request.';
  return TransferOutcome(accepted: !failed, text: text);
}

/// A packet is complete only when the server says so and no mandatory item is missing.
InformationPacketView parseInformationPacket(Map<String, dynamic> json) {
  final missing = (json['missingItems'] as List?)
          ?.map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList() ??
      const <String>[];
  final items = (json['items'] as List?)
          ?.whereType<Map>()
          .map((raw) {
            final item = Map<String, dynamic>.from(raw);
            final title = '${item['title'] ?? item['code'] ?? ''}'.trim();
            return PacketLine(
              title: title.isEmpty ? 'Untitled item' : title,
              available: item['available'] == true,
              mandatory: item['mandatory'] != false,
            );
          })
          .toList() ??
      const <PacketLine>[];
  final missingMandatory = items
      .where((item) => item.mandatory && !item.available)
      .map((item) => item.title);
  final allMissing = {...missing, ...missingMandatory}.toList();
  final serverComplete = json['complete'] == true;
  final complete = serverComplete && allMissing.isEmpty;
  final statusText = '${json['completenessStatusText'] ?? ''}'.trim();
  return InformationPacketView(
    title: '${json['title'] ?? ''}'.trim(),
    regulation: '${json['regulationReference'] ?? ''}'.trim(),
    statusText: statusText.isNotEmpty
        ? statusText
        : complete
            ? 'Complete'
            : 'Incomplete',
    complete: complete,
    missing: allMissing,
    items: items,
  );
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
