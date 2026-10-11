/// كائن يمثل حالة اكتمال النموذج المقروءة من الخادم.
class SavedFormRead {
  final String? formStatus;
  final bool? complete;
  final String? message;

  const SavedFormRead({this.formStatus, this.complete, this.message});
}

/// نتيجة حفظ النموذج (أونلاين أو أوفلاين).
class FormSaveResult {
  final bool isOffline;
  final SavedFormRead? syncedData;

  const FormSaveResult.offline() : isOffline = true, syncedData = null;

  const FormSaveResult.online(this.syncedData) : isOffline = false;
}
