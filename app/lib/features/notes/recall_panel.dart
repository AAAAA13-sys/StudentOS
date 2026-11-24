import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ponpon.dart';
import '../insights/insights_providers.dart';
import '../insights/ponpon_talk_slot.dart';
import 'quiz_sheet.dart';
import 'recall_controller.dart';
import 'recall_item.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// Persistent Leitner spaced-recall queue shown inside `Notes > Recall`.
class RecallPanel extends ConsumerWidget {
  const RecallPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RecallDeckState> deckAsync = ref.watch(
      recallControllerProvider,
    );
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final RecallDeckState? loaded = deckAsync.value;
    final bool suppressTalk =
        loaded == null || loaded.cards.isEmpty || loaded.dueCards.isEmpty;

    return Column(
      children: <Widget>[
        PonponTalkSlot(surface: PonponSurface.notes, suppress: suppressTalk),
        Expanded(
          child: deckAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object _, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: colors.error,
                  ),
                  AppSpacing.gapMd,
                  const Text('Couldn’t load your recall deck.'),
                  AppSpacing.gapLg,
                  FilledButton(
                    onPressed: () =>
                        ref.read(recallControllerProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (RecallDeckState deck) {
              if (deck.cards.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Ponpon(mood: PonponMood.happy, size: 88),
                        AppSpacing.gapMd,
                        Text(
                          'No recall cards yet',
                          textAlign: TextAlign.center,
                          style: textStyles.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          'Write "Q: question" and "A: answer" or "term :: answer" in a note.',
                          textAlign: TextAlign.center,
                          style: textStyles.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (deck.dueCards.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: <Widget>[
                    _SummaryCard(deck: deck),
                    AppSpacing.gapXl,
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Ponpon(mood: PonponMood.sleepy, size: 88),
                        AppSpacing.gapMd,
                        Text(
                          'All caught up for today',
                          textAlign: TextAlign.center,
                          style: textStyles.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (deck.nextUpcomingDate != null) ...<Widget>[
                          AppSpacing.gapXs,
                          Text(
                            'Next review: ${deck.nextUpcomingDate}',
                            textAlign: TextAlign.center,
                            style: textStyles.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFeatures: _tabular,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(recallControllerProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  itemCount: deck.dueCards.length + 1,
                  separatorBuilder: (_, _) => AppSpacing.gapSm,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: _SummaryCard(deck: deck),
                      );
                    }
                    final int cardIndex = index - 1;
                    final DeckCard item = deck.dueCards[cardIndex];
                    return _DueCardTile(
                      item: item,
                      onTap: () => showRecallDeckSheet(
                        context,
                        deck.dueCards,
                        initialIndex: cardIndex,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.deck});

  final RecallDeckState deck;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final int dueCount = deck.dueCards.length;
    final List<int> boxCounts = List<int>.filled(5, 0);
    for (final DeckCard card in deck.cards) {
      boxCounts[card.box.clamp(1, 5) - 1]++;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        dueCount > 0 ? '$dueCount due today' : 'All caught up',
                        style: textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: _tabular,
                        ),
                      ),
                      if (deck.examPriorityCount > 0) ...<Widget>[
                        AppSpacing.gapXs,
                        Text(
                          '${deck.examPriorityCount} ${deck.examPriorityCount == 1 ? 'card' : 'cards'} linked to upcoming exams',
                          style: textStyles.bodySmall?.copyWith(
                            color: colors.tertiary,
                            fontWeight: FontWeight.w600,
                            fontFeatures: _tabular,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${deck.cards.length} total',
                  style: textStyles.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontFeatures: _tabular,
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (int b = 1; b <= 5; b++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: boxCounts[b - 1] > 0
                          ? colors.primaryContainer.withValues(alpha: 0.6)
                          : colors.surfaceContainerLow,
                      borderRadius: AppRadius.small,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text(
                      'Box $b: ${boxCounts[b - 1]}',
                      style: textStyles.labelSmall?.copyWith(
                        color: boxCounts[b - 1] > 0
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
              ],
            ),
            AppSpacing.gapMd,
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              child: FilledButton.icon(
                onPressed: dueCount == 0
                    ? null
                    : () => showRecallDeckSheet(context, deck.dueCards),
                icon: const Icon(Icons.bolt_rounded),
                label: Text('Review due ($dueCount)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueCardTile extends StatelessWidget {
  const _DueCardTile({required this.item, required this.onTap});

  final DeckCard item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.card.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      item.note.title.isEmpty ? 'Untitled' : item.note.title,
                      style: textStyles.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
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
                          fontWeight: FontWeight.w600,
                          fontFeatures: _tabular,
                        ),
                      ),
                    ),
                    if (item.examCountdown != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
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
                              size: 13,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
