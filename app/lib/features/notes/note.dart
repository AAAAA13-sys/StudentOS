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

  /// Active recall question-answer cards extracted from [body].
  List<RecallCard> get recallCards => extractRecallCards(body);
}

class RecallCard {
  const RecallCard({required this.question, required this.answer});
  final String question;
  final String answer;
}

/// Parses active recall questions and answers from plain text notes.
///
/// Supports:
/// - Multi-line format:
///     Q: What is F=ma?
///     A: Newton's Second Law
/// - Single-line flashcard format:
///     Mitochondria :: Powerhouse of the cell
List<RecallCard> extractRecallCards(String text) {
  if (text.trim().isEmpty) return const <RecallCard>[];
  final List<RecallCard> cards = <RecallCard>[];
  final List<String> lines = text.split('\n');

  String? pendingQuestion;

  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i].trim();
    if (line.isEmpty) continue;

    final RegExp qMatch = RegExp(r'^(?:Q|q|Question|question)\s*[:\-\)]\s*(.*)$');
    final RegExp aMatch = RegExp(r'^(?:A|a|Answer|answer)\s*[:\-\)]\s*(.*)$');

    final Match? q = qMatch.firstMatch(line);
    if (q != null) {
      pendingQuestion = q.group(1)?.trim();
      continue;
    }

    final Match? a = aMatch.firstMatch(line);
    if (a != null && pendingQuestion != null && pendingQuestion.isNotEmpty) {
      final String answer = a.group(1)?.trim() ?? '';
      cards.add(RecallCard(question: pendingQuestion, answer: answer));
      pendingQuestion = null;
      continue;
    }

    if (line.contains('::') || line.contains('||')) {
      final String sep = line.contains('::') ? '::' : '||';
      final List<String> parts = line.split(sep);
      if (parts.length >= 2 &&
          parts[0].trim().isNotEmpty &&
          parts[1].trim().isNotEmpty) {
        cards.add(
          RecallCard(
            question: parts[0].trim(),
            answer: parts.sublist(1).join(sep).trim(),
          ),
        );
      }
    }
  }

  return cards;
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
