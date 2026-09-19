class ApiResponse<T> {
  final int code;
  final bool status;
  final T? data;
  final String? message;
  final String? error;
  final Map<String, List<String>>? headers;

  ApiResponse({
    required this.code,
    required this.status,
    this.data,
    this.message,
    this.error,
    this.headers,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse(
      code: json['code'] as int? ?? 200,
      status: json['status'] as bool? ?? false,
      data: (json['data'] != null && fromJsonT != null)
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}
