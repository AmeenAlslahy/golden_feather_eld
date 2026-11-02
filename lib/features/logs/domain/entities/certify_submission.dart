/// نتيجة إرسال طلب الاعتماد إلى الخادم أو إلى طابور المزامنة.
///
/// [confirmed] تعني أن الخادم أكّد أن السجل أصبح معتمدًا. [pendingSync]
/// تعني أن الطلب محفوظ محليًا فقط، ولم يُعتمد السجل بعد — لا يجوز عرضه
/// كاعتماد نهائي قبل تأكيد الخادم.
enum CertifySubmissionStatus { confirmed, pendingSync }

class CertifySubmission {
  final CertifySubmissionStatus status;

  const CertifySubmission._(this.status);

  const CertifySubmission.confirmed()
    : this._(CertifySubmissionStatus.confirmed);

  const CertifySubmission.pendingSync()
    : this._(CertifySubmissionStatus.pendingSync);

  bool get isConfirmed => status == CertifySubmissionStatus.confirmed;

  bool get isPendingSync => status == CertifySubmissionStatus.pendingSync;
}
