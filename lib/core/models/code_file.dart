class CodeFile {
  final String id;
  final String name;
  final String content;
  final DateTime createdAt;
  final DateTime lastModified;
  final String? description;
  final List<String> tags;

  const CodeFile({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.lastModified,
    this.description,
    this.tags = const [],
  });

  factory CodeFile.create({
    required String name,
    required String content,
    String? description,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return CodeFile(
      id: _generateId(),
      name: name,
      content: content,
      createdAt: now,
      lastModified: now,
      description: description,
      tags: tags,
    );
  }

  factory CodeFile.fromJson(Map<String, dynamic> json) {
    return CodeFile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastModified: DateTime.parse(json['lastModified'] ?? DateTime.now().toIso8601String()),
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'description': description,
      'tags': tags,
    };
  }

  CodeFile copyWith({
    String? id,
    String? name,
    String? content,
    DateTime? createdAt,
    DateTime? lastModified,
    String? description,
    List<String>? tags,
  }) {
    return CodeFile(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }

  CodeFile updateContent(String newContent) {
    return copyWith(
      content: newContent,
      lastModified: DateTime.now(),
    );
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  bool get isEmpty => content.isEmpty;
  bool get isNotEmpty => content.isNotEmpty;
  int get lineCount => content.split('\n').length;
  int get characterCount => content.length;

  @override
  String toString() {
    return 'CodeFile(id: $id, name: $name, content: ${content.substring(0, content.length.clamp(0, 50))}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CodeFile &&
        other.id == id &&
        other.name == name &&
        other.content == content;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, content);
  }
}