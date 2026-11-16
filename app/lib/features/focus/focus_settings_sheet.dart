import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'focus_controller.dart';
import 'focus_plan.dart';
import 'focus_platform.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

Future<void> showFocusSettings(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext ctx) => const _FocusSettingsSheet(),
    );

class _FocusSettingsSheet extends ConsumerStatefulWidget {
  const _FocusSettingsSheet();

  @override
  ConsumerState<_FocusSettingsSheet> createState() =>
      _FocusSettingsSheetState();
}

class _FocusSettingsSheetState extends ConsumerState<_FocusSettingsSheet> {
  FocusSettings? _s;
  late final TextEditingController _phrase = TextEditingController();

  @override
  void dispose() {
    _phrase.dispose();
    super.dispose();
  }

  void _set(FocusSettings s) => setState(() => _s = s);

  Future<void> _save() async {
    final FocusSettings s = _s!.copyWith(
      exitPhrase: _phrase.text.trim().isEmpty
          ? defaultExitPhrase
          : _phrase.text.trim(),
    );
    final NavigatorState nav = Navigator.of(context);
    await ref.read(focusControllerProvider.notifier).saveSettings(s);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final FocusSettings? loaded = ref
        .watch(focusControllerProvider)
        .value
        ?.settings;
    if (_s == null && loaded != null) {
      _s = loaded;
      _phrase.text = loaded.exitPhrase;
    }
    final FocusSettings? s = _s;
    if (s == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final TextTheme text = context.textStyles;
    final ColorScheme colors = context.colors;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          Text(
            'Timer settings',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              ActionChip(
                label: const Text('Classic 25 / 5'),
                onPressed: () => _set(
                  s.copyWith(
                    focusMinutes: 25,
                    shortBreakMinutes: 5,
                    longBreakMinutes: 15,
                    rounds: 4,
                    longBreakEvery: 4,
                  ),
                ),
              ),
              ActionChip(
                label: const Text('Deep 50 / 10'),
                onPressed: () => _set(
                  s.copyWith(
                    focusMinutes: 50,
                    shortBreakMinutes: 10,
                    longBreakMinutes: 20,
                    rounds: 3,
                    longBreakEvery: 3,
                  ),
                ),
              ),
              ActionChip(
                label: const Text('Plain timer'),
                onPressed: () => _set(s.copyWith(rounds: 1)),
              ),
            ],
          ),

          section('Lengths'),
          _MinutesRow(
            label: 'Focus',
            value: s.focusMinutes,
            min: 5,
            max: 180,
            step: 5,
            onChanged: (int v) => _set(s.copyWith(focusMinutes: v)),
          ),
          _MinutesRow(
            label: 'Rounds',
            value: s.rounds,
            min: 1,
            max: 12,
            unit: '',
            onChanged: (int v) => _set(s.copyWith(rounds: v)),
          ),
          if (s.rounds > 1) ...<Widget>[
            _MinutesRow(
              label: 'Short break',
              value: s.shortBreakMinutes,
              min: 0,
              max: 30,
              onChanged: (int v) => _set(s.copyWith(shortBreakMinutes: v)),
            ),
            _MinutesRow(
              label: 'Long break',
              value: s.longBreakMinutes,
              min: 0,
              max: 60,
              step: 5,
              onChanged: (int v) => _set(s.copyWith(longBreakMinutes: v)),
            ),
            _MinutesRow(
              label: 'Long break every',
              value: s.longBreakEvery,
              min: 2,
              max: 6,
              unit: ' rounds',
              onChanged: (int v) => _set(s.copyWith(longBreakEvery: v)),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Chime when a phase changes'),
            value: s.chime,
            onChanged: (bool v) => _set(s.copyWith(chime: v)),
          ),

          section('Lockdown while focusing'),
          SegmentedButton<Lockdown>(
            showSelectedIcon: false,
            segments: <ButtonSegment<Lockdown>>[
              for (final Lockdown l in Lockdown.values)
                ButtonSegment<Lockdown>(value: l, label: Text(l.label)),
            ],
            selected: <Lockdown>{s.lockdown},
            onSelectionChanged: (Set<Lockdown> v) =>
                _set(s.copyWith(lockdown: v.first)),
          ),
          AppSpacing.gapXs,
          Text(
            s.lockdown.description,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (s.lockdown == Lockdown.strict) ...<Widget>[
            AppSpacing.gapMd,
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apps_rounded),
              title: const Text('Apps that stay open'),
              subtitle: Text(
                s.allowedApps.isEmpty
                    ? 'None. Calls, alarms and the keyboard always work.'
                    : '${s.allowedApps.length} chosen',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final List<String>? picked = await _pickApps(
                  context,
                  s.allowedApps,
                );
                if (picked != null) _set(s.copyWith(allowedApps: picked));
              },
            ),
            TextField(
              controller: _phrase,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Exit sentence',
                helperText: 'Typed exactly to pause or stop a focus round',
              ),
            ),
          ],
          AppSpacing.gapXl,
          SizedBox(
            height: AppSizes.buttonHeight,
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }

  Future<List<String>?> _pickApps(
    BuildContext context,
    List<String> current,
  ) async {
    final List<InstalledApp> apps = await ref
        .read(focusPlatformProvider)
        .launchableApps();
    if (!context.mounted) return null;
    final Set<String> chosen = current.toSet();
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setState) => Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Apps that stay open',
                      style: ctx.textStyles.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, chosen.toList()),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: apps.isEmpty
                  ? const Center(child: Text('No apps found.'))
                  : ListView(
                      children: <Widget>[
                        for (final InstalledApp app in apps)
                          CheckboxListTile(
                            title: Text(app.label),
                            value: chosen.contains(app.package),
                            onChanged: (bool? on) => setState(
                              () => on == true
                                  ? chosen.add(app.package)
                                  : chosen.remove(app.package),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinutesRow extends StatelessWidget {
  const _MinutesRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.unit = ' min',
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        IconButton(
          tooltip: 'Less',
          icon: const Icon(Icons.remove_rounded),
          onPressed: value - step < min ? null : () => onChanged(value - step),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 84),
          child: Text(
            value == 0 && unit == ' min' ? 'None' : '$value$unit',
            textAlign: TextAlign.center,
            style: context.textStyles.titleMedium?.copyWith(
              fontFeatures: _tabular,
            ),
          ),
        ),
        IconButton(
          tooltip: 'More',
          icon: const Icon(Icons.add_rounded),
          onPressed: value + step > max ? null : () => onChanged(value + step),
        ),
      ],
    );
  }
}
