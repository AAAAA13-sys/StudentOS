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
}
