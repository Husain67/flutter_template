class CodeExecutionResult {
  final bool success;
  final String output;
  final String error;
  final int executionTime;
  final List<String>? warnings;
  final Map<String, dynamic>? metadata;

  const CodeExecutionResult({
    required this.success,
    required this.output,
    required this.error,
    required this.executionTime,
    this.warnings,
    this.metadata,
  });

  factory CodeExecutionResult.fromJson(Map<String, dynamic> json) {
    return CodeExecutionResult(
      success: json['success'] ?? (json['result'] != null),
      output: json['result'] ?? json['output'] ?? '',
      error: json['error'] ?? json['issues']?.toString() ?? '',
      executionTime: json['executionTime'] ?? 0,
      warnings: json['warnings']?.cast<String>(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'output': output,
      'error': error,
      'executionTime': executionTime,
      'warnings': warnings,
      'metadata': metadata,
    };
  }

  bool get hasOutput => output.isNotEmpty;
  bool get hasError => error.isNotEmpty;
  bool get hasWarnings => warnings != null && warnings!.isNotEmpty;

  CodeExecutionResult copyWith({
    bool? success,
    String? output,
    String? error,
    int? executionTime,
    List<String>? warnings,
    Map<String, dynamic>? metadata,
  }) {
    return CodeExecutionResult(
      success: success ?? this.success,
      output: output ?? this.output,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      warnings: warnings ?? this.warnings,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'CodeExecutionResult(success: $success, output: $output, error: $error, executionTime: $executionTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CodeExecutionResult &&
        other.success == success &&
        other.output == output &&
        other.error == error &&
        other.executionTime == executionTime;
  }

  @override
  int get hashCode {
    return Object.hash(success, output, error, executionTime);
  }
}