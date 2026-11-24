import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ponpon.dart';
import 'global_search.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

WidgetRef? _findHostRef(BuildContext hostContext, BuildContext callerContext) {
  WidgetRef? found;
  hostContext.visitAncestorElements((Element element) {
    if (element is WidgetRef) {
      found = element as WidgetRef;
      return false;
    }
    return true;
  });
  if (found != null) return found;
  if (callerContext.mounted) {
    if (callerContext is WidgetRef) return callerContext as WidgetRef;
    callerContext.visitAncestorElements((Element element) {
      if (element is WidgetRef) {
        found = element as WidgetRef;
        return false;
      }
      return true;
    });
  }
  return found;
}

/// Opens the cross-tab global search and quick-command palette on the root
/// navigator so it covers the bottom bar from any tab or drawer.
Future<void> showCommandPalette(BuildContext context) {
  final BuildContext hostContext = Navigator.of(
    context,
    rootNavigator: true,
  ).context;
  final WidgetRef? hostRef = _findHostRef(hostContext, context);
  final ProviderContainer container = ProviderScope.containerOf(hostContext);

  return showModalBottomSheet<void>(
    context: hostContext,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _CommandPaletteSheet(
        hostContext: hostContext,
        hostRef: hostRef,
        container: container,
      ),
    ),
  );
}

class _CommandPaletteSheet extends ConsumerStatefulWidget {
  const _CommandPaletteSheet({
    required this.hostContext,
    required this.hostRef,
    required this.container,
  });

  final BuildContext hostContext;
  final WidgetRef? hostRef;
  final ProviderContainer container;

  @override
  ConsumerState<_CommandPaletteSheet> createState() =>
      _CommandPaletteSheetState();
}

class _CommandPaletteSheetState extends ConsumerState<_CommandPaletteSheet> {
  final TextEditingController _queryController = TextEditingController();
  String _groupFilter = 'All';
  List<SearchHit>? _snapshot;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<SearchHit> hits = await loadGlobalSearchSnapshot(ref);
      if (!mounted) return;
      setState(() {
        _snapshot = hits;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _selectHit(SearchHit hit) async {
    final BuildContext hostContext = widget.hostContext;
    final WidgetRef editorRef = widget.hostRef ?? ref;
    Navigator.pop(context);
    if (!hostContext.mounted) return;
    await hit.onSelect(hostContext, editorRef);
  }

  IconData _iconFor(SearchHitKind kind) => switch (kind) {
    SearchHitKind.command => Icons.bolt_rounded,
    SearchHitKind.event => Icons.event_rounded,
    SearchHitKind.shift => Icons.work_outline_rounded,
    SearchHitKind.task => Icons.check_circle_outline_rounded,
    SearchHitKind.note => Icons.article_outlined,
    SearchHitKind.transaction => Icons.swap_horiz_rounded,
    SearchHitKind.bill => Icons.receipt_long_outlined,
    SearchHitKind.goal => Icons.savings_outlined,
    SearchHitKind.iou => Icons.people_outline_rounded,
    SearchHitKind.alarm => Icons.alarm_rounded,
  };

  Color _accentFor(
    SearchHit hit,
    ColorScheme colors,
    ModuleColors moduleColors,
  ) => switch (hit.kind) {
    SearchHitKind.command => colors.primary,
    SearchHitKind.event || SearchHitKind.shift || SearchHitKind.alarm =>
      moduleColors.calendar,
    SearchHitKind.transaction =>
      hit.badge == 'Income' ? moduleColors.income : moduleColors.expense,
    SearchHitKind.bill || SearchHitKind.iou => moduleColors.expense,
    SearchHitKind.goal => moduleColors.income,
    SearchHitKind.note || SearchHitKind.task => moduleColors.notes,
  };

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextTheme textStyles = context.textStyles;
    final ModuleColors moduleColors = context.moduleColors;
    final List<SearchHit>? all = _snapshot;
    final List<SearchHit> results = all == null
        ? const <SearchHit>[]
        : filterAndRankHits(
            all,
            _queryController.text,
            groupFilter: _groupFilter,
          );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _queryController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search events, notes, tasks, money or commands',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _queryController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: 'Clear search',
                          onPressed: () {
                            setState(() => _queryController.clear());
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (results.isNotEmpty) {
                    _selectHit(results.first);
                  }
                },
              ),
              AppSpacing.gapSm,
              SizedBox(
                height: AppSizes.minTouchTarget,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: searchGroupFilters.length,
                  separatorBuilder: (_, _) => AppSpacing.gapSm,
                  itemBuilder: (BuildContext ctx, int index) {
                    final String group = searchGroupFilters[index];
                    final bool selected = _groupFilter == group;
                    return Center(
                      child: FilterChip(
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        label: Text(group),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _groupFilter = group);
                        },
                      ),
                    );
                  },
                ),
              ),
              AppSpacing.gapSm,
              Flexible(
                child: _failed
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'Could not load search index.',
                                style: textStyles.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              AppSpacing.gapMd,
                              FilledButton(
                                onPressed: () {
                                  setState(() => _failed = false);
                                  _load();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : all == null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Ponpon(mood: PonponMood.smug, size: 80),
                              AppSpacing.gapMd,
                              Text(
                                'No matching items',
                                style: textStyles.titleMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => AppSpacing.gapSm,
                        itemBuilder: (BuildContext ctx, int index) {
                          final SearchHit hit = results[index];
                          final Color accent = _accentFor(
                            hit,
                            colors,
                            moduleColors,
                          );
                          return Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              minTileHeight: 56,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: accent.withValues(alpha: 0.14),
                                child: Icon(
                                  _iconFor(hit.kind),
                                  size: AppSizes.iconSm,
                                  color: accent,
                                ),
                              ),
                              title: Text(
                                hit.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyles.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: _tabular,
                                ),
                              ),
                              subtitle: hit.subtitle.isNotEmpty
                                  ? Text(
                                      hit.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textStyles.bodySmall?.copyWith(
                                        fontFeatures: _tabular,
                                      ),
                                    )
                                  : null,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.secondaryContainer,
                                  borderRadius: AppRadius.pill,
                                  border: Border.all(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  hit.badge,
                                  style: textStyles.labelSmall?.copyWith(
                                    color: colors.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () => _selectHit(hit),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
