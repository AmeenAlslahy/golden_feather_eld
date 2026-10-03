/// نماذج التحويل الصرفة — لا استيراد لـ Flutter ولا l10n هنا.
///
/// قراءة أجسام الخادم (الـ parsing) في
/// `data/mappers/inspection_mappers.dart`؛ والتحقق من مدخلات الواجهة
/// قاعدة صرفة يستهلكها الـ presentation ويعرض رسالتها المترجمة.
library;

/// طريقة نقل السجلات (SRS 8.4 telematics / email).
enum TransferMethod {
  webService,
  email,
  bluetooth,
  usb;
}

/// The live send path rejects a comment outside 4–60 characters; the UI
/// localizes the refusal with `inspectionCommentErrorLength`.
bool isValidInspectionComment(String comment) {
  final length = comment.trim().length;
  return length >= 4 && length <= 60;
}

class TransferOutcome {
  final bool accepted;
  final String text;

  const TransferOutcome({required this.accepted, required this.text});
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
