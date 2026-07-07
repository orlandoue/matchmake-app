class PolicyModel {
  final String id;
  final String slug;
  final String title;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PolicyModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    return PolicyModel(
      id: json['id'] as String,
      slug: (json['slug'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      content: (json['content'] as String? ?? '').trim(),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
