// API Response Model - Data Layer
//
// Generic wrapper for all API responses from BE-CloseExp.
// Matches the ApiResponse T structure from the backend.
class ApiResponseModel<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;

  const ApiResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  /// Create from JSON with a data parser function
  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? dataParser,
  ) {
    return ApiResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'] as Map<String, dynamic>)
          : null,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
    );
  }

  /// Create from JSON with raw data (no parsing)
  factory ApiResponseModel.fromJsonRaw(Map<String, dynamic> json) {
    return ApiResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] as T?,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
