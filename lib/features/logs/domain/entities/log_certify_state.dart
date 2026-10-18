import 'package:equatable/equatable.dart';

/// حالة شاشة الاعتماد من الخادم (`GET /eld/daily-logs/{id}/certify`).
///
/// المصدر الأول لقرار "هل يمكن الاعتماد الآن" + الأسباب المانعة
/// ([validationCodes])؛ عند غياب هذا الرد تُستخدم الجاهزية
/// (`/readiness`) كاحتياط متسامح.
class LogCertifyState extends Equatable {
  final int dailyLogId;
  final String logDate;

  /// النص القانوني الذي يوقّع عليه السائق.
  final String statementText;
  final String ruleReference;

  /// توقيع مسجّل مسبقاً على الخادم.
  final bool hasSignature;
  final String? signatureImageData;

  final String certificationStatus;
  final bool certified;
  final bool canCertify;

  /// رموز مانعة من الخادم، مثل `FORM_NOT_FINAL` أو `SIGNATURE_REQUIRED`.
  final List<String> validationCodes;

  const LogCertifyState({
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

  @override
  List<Object?> get props => [
        dailyLogId,
        logDate,
        statementText,
        ruleReference,
        hasSignature,
        signatureImageData,
        certificationStatus,
        certified,
        canCertify,
        validationCodes,
      ];
}
