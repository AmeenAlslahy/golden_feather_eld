import 'dart:convert';

/// ترميز توقيع السائق — كيان DVIR يخزن التوقيع كنص base64 لصورة PNG
/// (شكل `signatureData` على الخادم). مُعرّف محلي مثل `signature_1` ليس
/// توقيعاً ولا يُقبل.
String? dvirSignatureData(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  return base64Encode(bytes);
}
