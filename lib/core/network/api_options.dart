class ApiOptions {
  final Map<String, dynamic>? headers;
  final String? contentType;
  final String? responseType; // e.g. 'plain', 'bytes', 'json'
  final bool? followRedirects;
  final bool Function(int?)? validateStatus;

  ApiOptions({
    this.headers,
    this.contentType,
    this.responseType,
    this.followRedirects,
    this.validateStatus,
  });
}
