/// POST /eld/daily-logs/{id}/certify — request body per the daily-log API
/// specification (2026-10): `{ certified, signatureImage }`.
class CertifyRequestDto {
  /// Log id — carried for the URL (`EldEndpoints.certifyLog`) only; the
  /// spec body does not include it.
  final int dailyLogId;
  final bool certified;

  /// Base64-encoded PNG of the drawn signature (optional; the server
  /// validates it against its own requirements).
  final String? signatureImage;

  const CertifyRequestDto({
    required this.dailyLogId,
    required this.certified,
    this.signatureImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'certified': certified,
      if (signatureImage != null && signatureImage!.isNotEmpty)
        'signatureImage': signatureImage,
    };
  }
}

/// Response of POST /eld/daily-logs/{id}/certify.
///
/// Spec shape (2026-10):
/// ```json
/// { "dailyLogId": 1, "logDate": "...", "certification": {
///     "status": "CERTIFIED", "certified": true,
///     "certifiedAt": "...", "certificateId": "..." },
///   "logStatus": "..." }
/// ```
/// Flat legacy fields are still read as fallback.
class CertifyResponseDto {
  final int dailyLogId;
  final String logDate;
  final String certificationStatus;
  final bool isCertified;
  final String? certifiedAt;
  final String? certificateId;
  final String? logStatus;

  const CertifyResponseDto({
    required this.dailyLogId,
    this.logDate = '',
    required this.certificationStatus,
    required this.isCertified,
    this.certifiedAt,
    this.certificateId,
    this.logStatus,
  });

  factory CertifyResponseDto.fromJson(Map<String, dynamic> json) {
    final cert = json['certification'] is Map
        ? Map<String, dynamic>.from(json['certification'] as Map)
        : const <String, dynamic>{};

    final status = (cert['status'] ?? json['certificationStatus'] ??
            json['logStatus'])
        ?.toString();

    return CertifyResponseDto(
      dailyLogId: (json['dailyLogId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      logDate: json['logDate']?.toString() ?? '',
      certificationStatus: status ?? 'UNCERTIFIED',
      isCertified: cert['certified'] == true ||
          json['isCertified'] == true ||
          status?.toUpperCase() == 'CERTIFIED',
      certifiedAt: cert['certifiedAt']?.toString() ??
          json['certifiedAt']?.toString(),
      certificateId: cert['certificateId']?.toString() ??
          json['certificateId']?.toString(),
      logStatus: json['logStatus']?.toString(),
    );
  }
}

/// GET /eld/daily-logs/{id}/certify — certification screen state.
///
/// Spec shape (2026-10):
/// ```json
/// { "dailyLogId": 1, "logDate": "...",
///   "statement": { "text": "...", "ruleReference": "..." },
///   "signature": { "imageData": "...", "hasSignature": true },
///   "certificationStatus": "UNCERTIFIED", "certified": false,
///   "canCertify": true, "validationCodes": [] }
/// ```
class CertifyStateDto {
  final int dailyLogId;
  final String logDate;

  /// The legal certification statement the driver signs under.
  final String statementText;
  final String ruleReference;

  /// Whether a signature is already on record on the server.
  final bool hasSignature;
  final String? signatureImageData;

  final String certificationStatus;
  final bool certified;
  final bool canCertify;

  /// Machine-readable blockers, e.g. `FORM_NOT_FINAL`,
  /// `SIGNATURE_REQUIRED`, `UNCERTIFIED_EDITS_PENDING`, `HOS_VIOLATION`.
  final List<String> validationCodes;

  const CertifyStateDto({
    required this.dailyLogId,
    this.logDate = '',
    this.statementText = '',
    this.ruleReference = '',
    this.hasSignature = false,
    this.signatureImageData,
    this.certificationStatus = 'UNCERTIFIED',
    this.certified = false,
    this.canCertify = false,
    this.validationCodes = const [],
  });

  factory CertifyStateDto.fromJson(Map<String, dynamic> json) {
    final statement = json['statement'] is Map
        ? Map<String, dynamic>.from(json['statement'] as Map)
        : const <String, dynamic>{};
    final signature = json['signature'] is Map
        ? Map<String, dynamic>.from(json['signature'] as Map)
        : const <String, dynamic>{};
    final status = json['certificationStatus']?.toString();

    return CertifyStateDto(
      dailyLogId: (json['dailyLogId'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      logDate: json['logDate']?.toString() ?? '',
      statementText: statement['text']?.toString() ??
          json['statementText']?.toString() ??
          '',
      ruleReference: statement['ruleReference']?.toString() ??
          json['ruleReference']?.toString() ??
          '',
      hasSignature: signature['hasSignature'] == true ||
          json['hasSignature'] == true ||
          (signature['imageData']?.toString() ?? '').isNotEmpty,
      signatureImageData: signature['imageData']?.toString() ??
          json['signatureImageData']?.toString(),
      certificationStatus: status ?? 'UNCERTIFIED',
      certified: json['certified'] == true ||
          json['isCertified'] == true ||
          status?.toUpperCase() == 'CERTIFIED',
      canCertify: json['canCertify'] == true,
      validationCodes: (json['validationCodes'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}
