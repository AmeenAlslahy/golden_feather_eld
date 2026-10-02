class SavedFormRead {
  final String? formStatus;
  final bool? complete;
  final String? message;

  const SavedFormRead({this.formStatus, this.complete, this.message});
}

/// Reads completeness from the save response. A missing status is not complete.
SavedFormRead readSavedForm(Map<String, dynamic> json) {
  final body = json['data'] is Map
      ? Map<String, dynamic>.from(json['data'] as Map)
      : json;
  final raw = body['formStatus']?.toString().trim();
  final message = body['message']?.toString().trim();
  final text = message == null || message.isEmpty ? null : message;
  if (raw == null || raw.isEmpty) {
    return SavedFormRead(message: text);
  }
  final upper = raw.toUpperCase();
  final bool? complete = switch (upper) {
    'COMPLETED' || 'COMPLETE' => true,
    'INCOMPLETE' || 'IN_PROGRESS' => false,
    _ => null,
  };
  return SavedFormRead(formStatus: raw, complete: complete, message: text);
}

class FormSaveResult {
  final bool isOffline;
  final SavedFormRead? syncedData;

  const FormSaveResult.offline() : isOffline = true, syncedData = null;

  const FormSaveResult.online(this.syncedData) : isOffline = false;
}
