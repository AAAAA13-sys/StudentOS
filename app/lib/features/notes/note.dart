class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      tags: (json['tags'] as List? ?? <dynamic>[]).cast<String>(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'body': body,
      'tags': tags,
    };
  }
}
