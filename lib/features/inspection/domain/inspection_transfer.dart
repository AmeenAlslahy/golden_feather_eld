import '../../../../l10n/app_localizations.dart';

/// The live send path rejects a comment outside 4–60 characters.
String? inspectionCommentError(String comment, {required AppLocalizations loc}) {
  final length = comment.trim().length;
  if (length < 4 || length > 60) {
    return loc.inspectionCommentErrorLength;
  }
  return null;
}

class TransferOutcome {
  final bool accepted;
  final String text;

  const TransferOutcome({required this.accepted, required this.text});
}

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

class PacketLine {
  final String title;
  final bool available;
  final bool mandatory;

  const PacketLine({
    required this.title,
    required this.available,
    required this.mandatory,
  });
}

class InformationPacketView {
  final String title;
  final String regulation;
  final String statusText;
  final bool complete;
  final List<String> missing;
  final List<PacketLine> items;

  const InformationPacketView({
    required this.title,
    required this.regulation,
    required this.statusText,
    required this.complete,
    required this.missing,
    required this.items,
  });
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
