/// The standard Laravel success envelope:
/// `{ "success": true, "message": "...", "data": <T>, "meta": {...}? }`
/// (confirmed against backend/tests/Feature/ApiResponseStructureTest.php).
class ApiResponse<T> {
  const ApiResponse({
    required this.message,
    required this.data,
    this.meta,
  });

  final String message;
  final T data;
  final ApiMeta? meta;

  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Object? data) parse,
  ) {
    return ApiResponse<T>(
      message: json['message'] as String? ?? '',
      data: parse(json['data']),
      meta: json['meta'] is Map<String, dynamic>
          ? ApiMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Pagination metadata returned for collection endpoints.
class ApiMeta {
  const ApiMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int perPage;
  final int total;

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
