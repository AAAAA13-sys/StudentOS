import 'dart:convert';

import '../../core/checklist.dart';

class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    this.createdAt,
    this.updatedAt,
    this.pinned = false,
  });

  final int id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool pinned;

  /// Active recall question-answer cards extracted from [body].
  List<RecallCard> get recallCards => extractRecallCards(body);

  /// Extracted recall cards paired with their deterministic, edit-stable key.
  List<({RecallCard card, String key})> get keyedRecallCards {
    final List<RecallCard> cards = recallCards;
    if (cards.isEmpty) return const <({RecallCard card, String key})>[];
    final Map<String, int> seen = <String, int>{};
    return <({RecallCard card, String key})>[
      for (final RecallCard card in cards)
        () {
          final String norm = normalizeRecallQuestion(card.question);
          final int occurrence = seen[norm] ?? 0;
          seen[norm] = occurrence + 1;
          return (
            card: card,
            key: recallCardKey(card.question, occurrence: occurrence),
          );
        }(),
    ];
  }

  /// Tickable `- [ ] text` lines in [body].
  List<ChecklistItem> get checklistItems => parseChecklist(body);
}

/// Normalizes a recall question for stable card key hashing.
String normalizeRecallQuestion(String question) =>
    question.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Deterministic 64-bit FNV-1a hex key for a recall question (ignoring answer
/// edits and whitespace/case tweaks). Duplicate questions inside one note are
/// disambiguated with [occurrence] (`0, 1, ...`).
String recallCardKey(String question, {int occurrence = 0}) {
  final String normalized = normalizeRecallQuestion(question);
  final String input = occurrence > 0 ? '$normalized#$occurrence' : normalized;
  final BigInt offsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
  final BigInt prime = BigInt.parse('100000001b3', radix: 16);
  final BigInt mask = BigInt.parse('ffffffffffffffff', radix: 16);

  BigInt hash = offsetBasis;
  for (final int byte in utf8.encode(input)) {
    hash ^= BigInt.from(byte);
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
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

    final RegExp qMatch = RegExp(
      r'^(?:Q|q|Question|question)\s*[:\-\)]\s*(.*)$',
    );
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
  final String firstLine = stripChecklistMarker(
    body.trim().split('\n').first.trim(),
  ).trim();
  if (firstLine.isEmpty) return null;
  return firstLine.length <= 60 ? firstLine : '${firstLine.substring(0, 60)}…';
}
