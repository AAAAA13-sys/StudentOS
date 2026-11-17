/// Markdown task lines (`- [ ] text`, `- [x] text`, `[ ] text`, `[X] text`)
/// inside free text, shared by events and notes.
typedef ChecklistItem = ({String text, bool done});

final RegExp _itemPattern = RegExp(r'^(?:-\s+)?\[([ xX])\]\s+(\S.*)$');

/// The checklist items in [text], in order. Lines with no text after the
/// marker are not items.
List<ChecklistItem> parseChecklist(String? text) {
  if (text == null || text.isEmpty) return const <ChecklistItem>[];
  final List<ChecklistItem> items = <ChecklistItem>[];
  for (final String line in text.split('\n')) {
    final RegExpMatch? m = _itemPattern.firstMatch(line.trim());
    if (m != null) {
      items.add((text: m.group(2)!.trim(), done: m.group(1) != ' '));
    }
  }
  return items;
}

/// [text] with the checklist item at [targetIndex] (counting items only)
/// ticked or unticked. Other lines are untouched; an out-of-range index
/// returns [text] unchanged.
String toggleChecklistLine(String text, int targetIndex) {
  if (text.isEmpty) return text;
  final List<String> lines = text.split('\n');
  int current = 0;
  for (int i = 0; i < lines.length; i++) {
    if (_itemPattern.firstMatch(lines[i].trim()) == null) continue;
    if (current == targetIndex) {
      lines[i] = lines[i].replaceFirstMapped(
        RegExp(r'\[([ xX])\]'),
        (Match m) => m.group(1) == ' ' ? '[x]' : '[ ]',
      );
      break;
    }
    current++;
  }
  return lines.join('\n');
}

/// The text of [line] without a checklist marker, or [line] itself.
String stripChecklistMarker(String line) {
  final RegExpMatch? m = _itemPattern.firstMatch(line.trim());
  return m == null ? line : m.group(2)!.trim();
}
