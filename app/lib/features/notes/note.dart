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

/// The title to save: what was typed, or else the first line of [body], so a
/// note can be captured without naming it. Null when both are empty.
String? noteTitleFor(String title, String body) {
  final String typed = title.trim();
  if (typed.isNotEmpty) return typed;
  final String firstLine = body.trim().split('\n').first.trim();
  if (firstLine.isEmpty) return null;
  return firstLine.length <= 60 ? firstLine : '${firstLine.substring(0, 60)}…';
}
