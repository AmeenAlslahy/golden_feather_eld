class CertifyRequestDto {
  final int dailyLogId;
  final int driverId;
  final String logDate;
  final String signatureCertificateId;
  final bool signatureConfirmation;
  final bool certifiedTrue;

  const CertifyRequestDto({
    required this.dailyLogId,
    required this.driverId,
    required this.logDate,
    required this.signatureCertificateId,
    required this.signatureConfirmation,
    required this.certifiedTrue,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailyLogId': dailyLogId,
      'driverId': driverId,
      'logDate': logDate,
      'signatureCertificateId': signatureCertificateId,
      'signatureConfirmation': signatureConfirmation,
      'certifiedTrue': certifiedTrue,
    };
  }
}

class CertifyResponseDto {
  final int dailyLogId;
  final String certificationStatus;
  final bool isCertified;
  // Can include nested driver, etc if needed

  const CertifyResponseDto({
    required this.dailyLogId,
    required this.certificationStatus,
    required this.isCertified,
  });

  factory CertifyResponseDto.fromJson(Map<String, dynamic> json) {
    return CertifyResponseDto(
      dailyLogId: (json['dailyLogId'] as num?)?.toInt() ?? 0,
      certificationStatus: json['certificationStatus']?.toString() ?? 'UNCERTIFIED',
      isCertified: json['isCertified'] == true || (json['certificationStatus']?.toString().toUpperCase() == 'CERTIFIED'),
    );
  }
}
