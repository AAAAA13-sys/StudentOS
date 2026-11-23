import 'package:flutter/material.dart';

import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';

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

/// One tickable checklist line: a 48dp-tall row that reads to TalkBack as a
/// checkbox with its text and state.
class ChecklistRow extends StatelessWidget {
  const ChecklistRow({
    required this.text,
    required this.done,
    required this.onToggle,
    this.maxLines,
    super.key,
  });

  final String text;
  final bool done;
  final VoidCallback onToggle;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Semantics(
      container: true,
      checked: done,
      label: text,
      onTap: onToggle,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: AppRadius.small,
          onTap: onToggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  done
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: AppSizes.iconMd,
                  color: done ? colors.primary : colors.onSurfaceVariant,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    text,
                    maxLines: maxLines,
                    overflow: maxLines != null ? TextOverflow.ellipsis : null,
                    style: context.textStyles.bodyMedium?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? colors.onSurfaceVariant : colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
