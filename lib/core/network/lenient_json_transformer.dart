import 'dart:convert';

import 'package:dio/dio.dart'; // ignore_architecture
import 'package:flutter/foundation.dart';

/// Top-level pure parsing function for lenient JSON decoding.
///
/// Can be invoked directly on the current isolate or offloaded to a background
/// isolate via [compute].
///
/// - Returns parsed JSON structure ([Map], [List], [num], [bool], [String], or `null`).
/// - On [FormatException] (e.g. malformed JSON, plain-text response, HTML error),
///   returns the original [text] unchanged, preserving the lenient fallback contract.
dynamic lenientJsonDecode(String text) {
  try {
    return jsonDecode(text);
  } on FormatException {
    return text;
  }
}

/// Dio's default JSON transformer throws [FormatException] on an empty
/// or non-JSON body (204, `200` with no payload, HTML). Several ELD
/// write paths return exactly that. Treat empty as `{}` and leave a
/// non-JSON string as a string so callers can map it without crashing.
///
/// Optimization (ISO-001):
/// Payloads exceeding [isolateThresholdBytes] (default: 50 KB) are decoded
/// inside a background worker isolate via [compute] to prevent blocking the UI
/// thread during large ELD multi-day log syncs. Smaller payloads are decoded
/// synchronously on the calling isolate to avoid isolate startup and serialization overhead.
class LenientJsonTransformer extends BackgroundTransformer {
  /// Default threshold in bytes (50 KB). Payloads strictly larger than this
  /// are parsed in a background isolate.
  static const int kDefaultIsolateThresholdBytes = 50 * 1024;

  /// The byte threshold above which response bodies are offloaded to an isolate.
  final int isolateThresholdBytes;

  LenientJsonTransformer({
    this.isolateThresholdBytes = kDefaultIsolateThresholdBytes,
  });

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

    // Approximation: In Dart, String.length measures UTF-16 code units.
    // For JSON payloads (predominantly ASCII syntax, keys, and values),
    // text.length provides an efficient O(1) estimate that avoids the memory
    // and time overhead of full utf8.encode(). Non-ASCII characters consume
    // >= 1 byte in UTF-8, so text.length conservatively approximates or
    // slightly underestimates UTF-8 bytes, ensuring large Unicode payloads
    // are still offloaded safely.
    if (text.length > isolateThresholdBytes) {
      return compute(lenientJsonDecode, text);
    }

    return lenientJsonDecode(text);
  }
}

