import 'dart:convert';

/// Who produced the logical duty transition.
enum DutyEventSource { manual, ecm, server }

/// Delivery/sync state of the recorded evidence.
///
/// `pendingReview` means the event has no legal timestamp yet (trusted time
/// was unavailable). It is retained but never applied to HOS or enqueued.
enum DutyEventSyncState {
  pendingReview,
  localOnly,
  queued,
  acked,
  rejected,
  superseded,
}

/// Which clock supplied `eventTimeUtc`.
enum DutyTimeSource { trusted, device, server }

/// How much the recorded event time can be trusted.
enum DutyTimeConfidence { trusted, stale, untrusted }

/// One append-only row of duty-event evidence.
///
/// Identity layers:
/// - [eventId] is the logical transition identity (queue `id` / `clientId`).
/// - [serverEventId] is filled only when the server echoes its own identity.
///
/// The row is never deleted. A rejection or ack changes [syncState].
class DutyEventRecord {
  const DutyEventRecord({
    required this.eventId,
    required this.ownerDriverId,
    required this.source,
    required this.status,
    required this.eventTimeUtc,
    required this.receivedAtUtc,
    required this.timeSource,
    required this.timeConfidence,
    required this.monotonicMs,
    required this.payload,
    required this.syncState,
    required this.createdAt,
    this.seq,
    this.serverEventId,
  });

  /// Insertion order assigned by SQLite (`NULL` before the first insert).
  final int? seq;
  final String eventId;
  final int? ownerDriverId;
  final DutyEventSource source;
  final String status;

  /// Legal event time. `null` only for [DutyEventSyncState.pendingReview].
  final DateTime? eventTimeUtc;

  /// When this device learned about the event. Metadata, not legal time.
  final DateTime receivedAtUtc;

  final DutyTimeSource timeSource;
  final DutyTimeConfidence timeConfidence;

  /// Monotonic elapsed milliseconds since the trusted-time anchor.
  final int? monotonicMs;

  /// Immutable event payload (location, odometer, notes, origin...).
  final Map<String, dynamic> payload;

  final DutyEventSyncState syncState;
  final String? serverEventId;
  final DateTime createdAt;

  Map<String, Object?> toRow() => {
    if (seq != null) 'seq': seq,
    'event_id': eventId,
    'owner_driver_id': ownerDriverId,
    'source': source.name,
    'status': status,
    'event_time_utc': eventTimeUtc?.toUtc().millisecondsSinceEpoch,
    'received_at_utc': receivedAtUtc.toUtc().millisecondsSinceEpoch,
    'time_source': timeSource.name,
    'time_confidence': timeConfidence.name,
    'monotonic_ms': monotonicMs,
    'payload': jsonEncode(payload),
    'sync_state': syncState.name,
    'server_event_id': serverEventId,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
  };

  /// Throws [FormatException] when a row cannot be decoded. The loader catches
  /// per row so one corrupt record cannot hide the rest of the evidence.
  factory DutyEventRecord.fromRow(Map<String, Object?> row) {
    final eventId = row['event_id'];
    final status = row['status'];
    final receivedAt = row['received_at_utc'];
    final createdAt = row['created_at'];
    if (eventId is! String || eventId.isEmpty) {
      throw const FormatException('journal row without event_id');
    }
    if (status is! String || status.isEmpty) {
      throw const FormatException('journal row without status');
    }
    if (receivedAt is! int || createdAt is! int) {
      throw const FormatException('journal row with invalid timestamps');
    }
    final payloadRaw = row['payload'];
    if (payloadRaw is! String) {
      throw const FormatException('journal row without payload');
    }
    final decoded = jsonDecode(payloadRaw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('journal payload is not an object');
    }
    final eventTimeRaw = row['event_time_utc'];
    final eventTime = eventTimeRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(eventTimeRaw, isUtc: true)
        : null;
    return DutyEventRecord(
      seq: row['seq'] is int ? row['seq'] as int : null,
      eventId: eventId,
      ownerDriverId: row['owner_driver_id'] is int
          ? row['owner_driver_id'] as int
          : null,
      source: DutyEventSource.values.firstWhere(
        (s) => s.name == row['source'],
        orElse: () => DutyEventSource.manual,
      ),
      status: status,
      eventTimeUtc: eventTime,
      receivedAtUtc: DateTime.fromMillisecondsSinceEpoch(
        receivedAt,
        isUtc: true,
      ),
      timeSource: DutyTimeSource.values.firstWhere(
        (s) => s.name == row['time_source'],
        orElse: () => DutyTimeSource.device,
      ),
      timeConfidence: DutyTimeConfidence.values.firstWhere(
        (s) => s.name == row['time_confidence'],
        orElse: () => DutyTimeConfidence.untrusted,
      ),
      monotonicMs: row['monotonic_ms'] is int
          ? row['monotonic_ms'] as int
          : null,
      payload: decoded,
      syncState: DutyEventSyncState.values.firstWhere(
        (s) => s.name == row['sync_state'],
        orElse: () => DutyEventSyncState.pendingReview,
      ),
      serverEventId: row['server_event_id'] is String
          ? row['server_event_id'] as String
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
    );
  }
}
