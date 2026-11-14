import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One raw BLE notification, kept for field diagnostics.
class BleFrameDiagnostic {
  const BleFrameDiagnostic({
    required this.timestamp,
    required this.kind,
    this.hex = '',
    this.ascii = '',
    this.characteristic,
    this.note,
  });

  final DateTime timestamp;
  final String kind;
  final String hex;
  final String ascii;
  final String? characteristic;
  final String? note;

  String get summary {
    final time = timestamp.toIso8601String().substring(11, 19);
    final asciiPart = ascii.trim().isEmpty ? '' : ' "$ascii"';
    return '$time $kind ${hex.isEmpty ? note ?? '' : hex}$asciiPart';
  }
}

/// Bounded in-memory ring buffer of BLE frames.
///
/// This is the fastest way to obtain the PT30-U wire format from the field:
/// the connection screen shows the last frames as hex + ASCII, so a screenshot
/// or a copied line is enough to finish the proprietary decoder.
class BleFrameMonitor extends ChangeNotifier {
  BleFrameMonitor._();

  static final BleFrameMonitor instance = BleFrameMonitor._();

  static const int _maxFrames = 60;

  final List<BleFrameDiagnostic> _frames = [];

  List<BleFrameDiagnostic> get frames => List.unmodifiable(_frames);

  void add(BleFrameDiagnostic frame) {
    _frames.add(frame);
    while (_frames.length > _maxFrames) {
      _frames.removeAt(0);
    }
    notifyListeners();
  }

  void addFrame({
    required String kind,
    String hex = '',
    String ascii = '',
    String? characteristic,
    String? note,
  }) {
    add(
      BleFrameDiagnostic(
        timestamp: DateTime.now(),
        kind: kind,
        hex: hex,
        ascii: ascii,
        characteristic: characteristic,
        note: note,
      ),
    );
  }

  void clear() {
    _frames.clear();
    notifyListeners();
  }
}

final bleFrameMonitorProvider = Provider<BleFrameMonitor>(
  (ref) => BleFrameMonitor.instance,
);
