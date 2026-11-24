import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'note.dart';
import 'quiz_session.dart';
import 'recall_controller.dart';
import 'recall_item.dart';

class _QuizItem {
  const _QuizItem({
    required this.card,
    required this.noteId,
    required this.cardKey,
    this.noteTitle,
    this.box,
    this.examCountdown,
  });

  final RecallCard card;
  final int noteId;
  final String cardKey;
  final String? noteTitle;
  final int? box;
  final String? examCountdown;
}

/// Opens the interactive Quiz sheet for [note]'s Q&A cards. Does nothing
/// when the note has none. Marks persist into the Leitner recall schedule.
Future<void> showQuizSheet(BuildContext context, Note note) async {
  final List<({RecallCard card, String key})> keyed = note.keyedRecallCards;
  if (keyed.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) {
      return _QuizSheetView(
        title: 'Quiz',
        headerNoteTitle: note.title,
        items: <_QuizItem>[
          for (final ({RecallCard card, String key}) entry in keyed)
            _QuizItem(card: entry.card, noteId: note.id, cardKey: entry.key),
        ],
      );
    },
  );
}

/// Opens the interactive Spaced Recall Deck sheet for cross-note due [cards].
/// Does nothing when [cards] is empty.
Future<void> showRecallDeckSheet(
  BuildContext context,
  List<DeckCard> cards, {
  String title = 'Recall deck',
  int initialIndex = 0,
}) async {
  if (cards.isEmpty) return;
  final int start = initialIndex.clamp(0, cards.length - 1);
  final List<DeckCard> ordered = start == 0
      ? cards
      : <DeckCard>[
          cards[start],
          ...cards.sublist(0, start),
          ...cards.sublist(start + 1),
        ];

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) {
      return _QuizSheetView(
        title: title,
        items: <_QuizItem>[
          for (final DeckCard deckCard in ordered)
            _QuizItem(
              card: deckCard.card,
              noteId: deckCard.note.id,
              cardKey: deckCard.cardKey,
              noteTitle: deckCard.note.title,
              box: deckCard.box,
              examCountdown: deckCard.examCountdown,
            ),
        ],
      );
    },
  );
}

class _QuizSheetView extends ConsumerStatefulWidget {
  const _QuizSheetView({
    required this.title,
    required this.items,
    this.headerNoteTitle,
  });

  final String title;
  final String? headerNoteTitle;
  final List<_QuizItem> items;

  @override
  ConsumerState<_QuizSheetView> createState() => _QuizSheetViewState();
}

class _QuizSheetViewState extends ConsumerState<_QuizSheetView> {
  late QuizSession _session = QuizSession(widget.items.length);
  final Set<int> _revealed = <int>{};

  void _toggle(int index) {
    setState(() {
      if (!_revealed.remove(index)) _revealed.add(index);
    });
  }

  void _toggleAll() {
    setState(() {
      if (_session.active.every(_revealed.contains)) {
        _revealed.clear();
      } else {
        _revealed.addAll(_session.active);
      }
    });
  }

  void _mark(int index, {required bool right}) {
    setState(() => _session.mark(index, right: right));
    final _QuizItem item = widget.items[index];
    final RecallController controller = ref.read(
      recallControllerProvider.notifier,
    );
    unawaited(_persistOutcome(controller, item.noteId, item.cardKey, right));
  }

  Future<void> _persistOutcome(
    RecallController controller,
    int noteId,
    String cardKey,
    bool right,
  ) async {
    try {
      await controller.recordOutcome(noteId, cardKey, right: right);
    } catch (_) {
      // Best-effort when rendered in isolated widget tests without a DB.
    }
  }

  void _retryMissed() {
    setState(() {
      _session = _session.retryMissed();
      _revealed.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final List<int> active = _session.active;
    final bool allRevealed = active.every(_revealed.contains);
    final String countLabel =
        '${active.length} ${active.length == 1 ? 'card' : 'cards'}';
    final String subtitle = widget.headerNoteTitle != null
        ? '${widget.headerNoteTitle} • $countLabel'
        : '$countLabel due';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.bolt_rounded,
                              size: 20,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.title,
                                style: textStyles.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _toggleAll,
                    icon: Icon(
                      allRevealed
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                    ),
                    label: Text(allRevealed ? 'Hide all' : 'Reveal all'),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: active.length + (_session.done ? 1 : 0),
                  separatorBuilder: (_, _) => AppSpacing.gapMd,
                  itemBuilder: (BuildContext context, int position) {
                    if (position == active.length) {
                      return _Tally(
                        session: _session,
                        onRetryMissed: _retryMissed,
                      );
                    }
                    final int index = active[position];
                    return _CardTile(
                      number: index + 1,
                      item: widget.items[index],
                      revealed: _revealed.contains(index),
                      result: _session.resultOf(index),
                      onToggle: () => _toggle(index),
                      onMark: (bool right) => _mark(index, right: right),
                    );
                  },
                ),
              ),
              AppSpacing.gapSm,
            ],
          ),
        );
      },
    );
  }
}

/// "6 of 10 right" with a button that reruns only the missed cards.
class _Tally extends StatelessWidget {
  const _Tally({required this.session, required this.onRetryMissed});

  final QuizSession session;
  final VoidCallback onRetryMissed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            session.tally,
            textAlign: TextAlign.center,
            style: textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onPrimaryContainer,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          if (session.missed.isNotEmpty) ...<Widget>[
            AppSpacing.gapSm,
            FilledButton(
              onPressed: onRetryMissed,
              child: const Text('Retry missed'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.number,
    required this.item,
    required this.revealed,
    required this.result,
    required this.onToggle,
    required this.onMark,
  });

  final int number;
  final _QuizItem item;
  final bool revealed;
  final bool? result;
  final VoidCallback onToggle;
  final ValueChanged<bool> onMark;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final RecallCard card = item.card;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(
          color: revealed
              ? colors.primary.withValues(alpha: 0.35)
              : colors.outlineVariant,
        ),
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (item.noteTitle != null ||
                item.box != null ||
                item.examCountdown != null) ...<Widget>[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (item.noteTitle != null && item.noteTitle!.isNotEmpty)
                    Text(
                      item.noteTitle!,
                      style: textStyles.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  if (item.box != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        'Box ${item.box}',
                        style: textStyles.labelSmall?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  if (item.examCountdown != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.event_rounded,
                            size: 12,
                            color: colors.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Exam ${item.examCountdown}',
                            style: textStyles.labelSmall?.copyWith(
                              color: colors.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              AppSpacing.gapSm,
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    'Q$number',
                    style: textStyles.labelSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    card.question,
                    style: textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            InkWell(
              onTap: onToggle,
              borderRadius: AppRadius.medium,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: revealed
                      ? colors.secondaryContainer.withValues(alpha: 0.5)
                      : colors.surfaceContainerLow,
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: revealed
                        ? colors.primary.withValues(alpha: 0.2)
                        : colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: revealed
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              card.answer,
                              style: textStyles.bodyMedium?.copyWith(
                                color: colors.onSurface,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.visibility_rounded,
                            size: 16,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to reveal answer',
                            style: textStyles.labelMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (revealed) ...<Widget>[
              AppSpacing.gapSm,
              Row(
                children: <Widget>[
                  Expanded(
                    child: _MarkButton(
                      label: 'Got it',
                      selected: result == true,
                      onPressed: () => onMark(true),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: _MarkButton(
                      label: 'Missed',
                      selected: result == false,
                      onPressed: () => onMark(false),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton.tonal(onPressed: onPressed, child: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
