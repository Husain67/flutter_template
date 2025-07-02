class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final String? error;
  final int? statusCode;

  const ApiResponse._({
    required this.success,
    this.data,
    required this.message,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success({
    required T data,
    String message = 'Success',
    int? statusCode,
  }) {
    return ApiResponse._(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error({
    required String message,
    String? error,
    int? statusCode,
  }) {
    return ApiResponse._(
      success: false,
      message: message,
      error: error,
      statusCode: statusCode,
    );
  }

  bool get isSuccess => success;
  bool get isError => !success;
  bool get hasData => data != null;

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, message: $message, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiResponse<T> &&
        other.success == success &&
        other.data == data &&
        other.message == message &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(success, data, message, error);
  }
}