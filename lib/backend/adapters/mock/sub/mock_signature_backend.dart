import 'dart:convert';

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../domain/signature/signature.dart';
import '../../../contracts/signature_backend.dart';

class MockSignatureBackend implements SignatureBackend {
  MockSignatureBackend();

  final List<Map<String, dynamic>> _saved = [];

  /// All saved signatures (for test assertions).
  List<Map<String, dynamic>> get savedSignatures => List.unmodifiable(_saved);

  void clear() => _saved.clear();

  @override
  Future<Result<SignatureCertificate>> save({
    required DriverId driverId,
    required String logDate,
    required String signatureDataBase64,
    required SignatureType type,
  }) async {
    final record = {
      'driverId': driverId.value,
      'logDate': logDate,
      'signatureData': signatureDataBase64,
      'signatureType': type.wire,
    };
    _saved.add(record);

    // Deterministic certificate.
    final hash = base64Encode(
      utf8.encode('mock-hash-${driverId.value}-$logDate'),
    );

    return ok(
      SignatureCertificate(
        signatureId: 'sig-${_saved.length}',
        driverId: driverId,
        logDate: logDate,
        signatureHash: hash,
        signedAt: DateTime.utc(2026, 1, 15, 10),
        status: CertificateStatus.valid,
      ),
    );
  }
}
