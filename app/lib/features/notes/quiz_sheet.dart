import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'note.dart';

/// Opens an interactive Active Recall study sheet for [note].
Future<void> showQuizSheet(BuildContext context, Note note) async {
  final List<RecallCard> cards = note.recallCards;
  if (cards.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) {
      return _QuizSheetView(note: note, cards: cards);
    },
  );
}

class _QuizSheetView extends StatefulWidget {
  const _QuizSheetView({required this.note, required this.cards});

  final Note note;
  final List<RecallCard> cards;

  @override
  State<_QuizSheetView> createState() => _QuizSheetViewState();
}

class _QuizSheetViewState extends State<_QuizSheetView> {
  late final Set<int> _revealed = <int>{};

  void _toggle(int index) {
    setState(() {
      if (_revealed.contains(index)) {
        _revealed.remove(index);
      } else {
        _revealed.add(index);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_revealed.length == widget.cards.length) {
        _revealed.clear();
      } else {
        _revealed.addAll(Iterable<int>.generate(widget.cards.length));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final bool allRevealed = _revealed.length == widget.cards.length;

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
                            Text(
                              'Active Recall',
                              style: textStyles.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.note.title} • ${widget.cards.length} ${widget.cards.length == 1 ? 'card' : 'cards'}',
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
                    label: Text(allRevealed ? 'Hide All' : 'Reveal All'),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: widget.cards.length,
                  separatorBuilder: (_, _) => AppSpacing.gapMd,
                  itemBuilder: (BuildContext context, int index) {
                    final RecallCard card = widget.cards[index];
                    final bool isRevealed = _revealed.contains(index);

                    return Card(
                      elevation: 0,
                      color: colors.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.large,
                        side: BorderSide(
                          color: isRevealed
                              ? colors.primary.withValues(alpha: 0.35)
                              : colors.outlineVariant,
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: AppSpacing.card,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
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
                                    'Q${index + 1}',
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
                              onTap: () => _toggle(index),
                              borderRadius: AppRadius.medium,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isRevealed
                                      ? colors.secondaryContainer.withValues(
                                          alpha: 0.5,
                                        )
                                      : colors.surfaceContainerLow,
                                  borderRadius: AppRadius.medium,
                                  border: Border.all(
                                    color: isRevealed
                                        ? colors.primary.withValues(alpha: 0.2)
                                        : colors.outlineVariant.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                                child: isRevealed
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              style: textStyles.bodyMedium
                                                  ?.copyWith(
                                                    color: colors.onSurface,
                                                    height: 1.4,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            Icons.visibility_rounded,
                                            size: 16,
                                            color: colors.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Tap to reveal answer',
                                            style: textStyles.labelMedium
                                                ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
