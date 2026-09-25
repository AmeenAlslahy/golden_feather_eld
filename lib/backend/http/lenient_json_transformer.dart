import 'dart:convert';

import 'package:dio/dio.dart';

/// Dio's default JSON transformer throws [FormatException] on an empty
/// or non-JSON body (204, `200` with no payload, HTML). Several ELD
/// write paths return exactly that. Treat empty as `{}` and leave a
/// non-JSON string as a string so callers can map it without crashing.
class LenientJsonTransformer extends BackgroundTransformer {
  @override
  Future<dynamic> transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    if (options.responseType != ResponseType.json) {
      return super.transformResponse(options, responseBody);
    }

    final raw = await super.transformResponse(
      options.copyWith(responseType: ResponseType.plain),
      responseBody,
    );
    if (raw == null) return <String, dynamic>{};
    if (raw is! String) return raw;

    final text = raw.trim();
    if (text.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }
}
