/// نتيجة إرسال طلب الاعتماد إلى الخادم أو إلى طابور المزامنة.
///
/// [confirmed] تعني أن الخادم أكّد أن السجل أصبح معتمدًا. [pendingSync]
/// تعني أن الطلب محفوظ محليًا فقط، ولم يُعتمد السجل بعد — لا يجوز عرضه
/// كاعتماد نهائي قبل تأكيد الخادم.
enum CertifySubmissionStatus { confirmed, pendingSync }

class CertifySubmission {
  final CertifySubmissionStatus status;
  final String? serverMessage;

  const CertifySubmission._(this.status, {this.serverMessage});

  const CertifySubmission.confirmed({String? serverMessage})
    : this._(CertifySubmissionStatus.confirmed, serverMessage: serverMessage);

  const CertifySubmission.pendingSync()
    : this._(CertifySubmissionStatus.pendingSync);

  bool get isConfirmed => status == CertifySubmissionStatus.confirmed;

  bool get isPendingSync => status == CertifySubmissionStatus.pendingSync;
}
