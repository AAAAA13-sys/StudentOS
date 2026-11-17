import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import 'alarm.dart';
import 'focus_controller.dart';
import 'focus_platform.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// Opens the editor for [alarm], or for a new alarm when it is null.
Future<void> showAlarmEditor(BuildContext context, {Alarm? alarm}) {
  final DateTime now = DateTime.now();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (BuildContext ctx) => _AlarmEditor(
      initial:
          alarm ??
          Alarm(id: 0, hour: (now.hour + 8) % 24, minute: 0, days: 0x1F),
    ),
  );
}

class _AlarmEditor extends ConsumerStatefulWidget {
  const _AlarmEditor({required this.initial});

  final Alarm initial;

  @override
  ConsumerState<_AlarmEditor> createState() => _AlarmEditorState();
}

class _AlarmEditorState extends ConsumerState<_AlarmEditor> {
  late Alarm _alarm = widget.initial;
  late final TextEditingController _label = TextEditingController(
    text: widget.initial.label,
  );
  late final TextEditingController _phrase = TextEditingController(
    text: widget.initial.phrase,
  );

  bool get _isNew => widget.initial.id == 0;

  @override
  void dispose() {
    _label.dispose();
    _phrase.dispose();
    super.dispose();
  }

  Alarm get _current =>
      _alarm.copyWith(label: _label.text.trim(), phrase: _phrase.text.trim());

  void _set(Alarm a) => setState(() => _alarm = a);

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _alarm.hour, minute: _alarm.minute),
    );
    if (picked != null) {
      _set(_alarm.copyWith(hour: picked.hour, minute: picked.minute));
    }
  }

  Future<void> _pickSound() async {
    final ({String uri, String name})? picked = await ref
        .read(focusPlatformProvider)
        .pickSound(_alarm.soundUri);
    if (picked == null) return;
    _set(
      picked.uri.isEmpty
          ? _alarm.copyWith(clearSound: true)
          : _alarm.copyWith(soundUri: picked.uri, soundName: picked.name),
    );
  }

  Future<void> _save() async {
    final Alarm alarm = _current.copyWith(enabled: true);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await ref.read(alarmControllerProvider.notifier).save(alarm);
    nav.pop();
    final DateTime? next = alarm.nextRing(DateTime.now());
    if (next != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Alarm rings ${ringsIn(next.difference(DateTime.now()))}',
          ),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final NavigatorState nav = Navigator.of(context);
    final bool ok = await confirmDestructive(
      context,
      title: 'Delete this alarm?',
      message: 'It will not ring again.',
      confirmLabel: 'Delete',
    );
    if (!ok) return;
    await ref.read(alarmControllerProvider.notifier).delete(widget.initial);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = context.textStyles;
    final ColorScheme colors = context.colors;
    final Alarm a = _alarm;
    final String time = TimeOfDay(
      hour: a.hour,
      minute: a.minute,
    ).format(context);

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
            _isNew ? 'New alarm' : 'Edit alarm',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          AppSpacing.gapMd,
          Center(
            child: TextButton(
              onPressed: _pickTime,
              child: Text(
                time,
                style: text.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: _tabular,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          AppSpacing.gapSm,
          _DayPicker(
            days: a.days,
            onChanged: (int d) => _set(a.copyWith(days: d)),
          ),
          AppSpacing.gapXs,
          Text(
            a.days == 0
                ? 'Rings once, then turns itself off.'
                : 'Repeats: ${a.daysLabel}.',
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          AppSpacing.gapMd,
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'e.g. 7 AM class',
            ),
          ),

          section('Sound'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.music_note_rounded),
            title: Text(a.soundName ?? "Phone's alarm sound"),
            subtitle: const Text('Tap to choose'),
            onTap: _pickSound,
          ),
          _SliderRow(
            label: 'Volume',
            valueLabel: '${a.volume}%',
            value: a.volume.toDouble(),
            min: 30,
            max: 100,
            divisions: 7,
            onChanged: (double v) => _set(a.copyWith(volume: v.round())),
          ),
          _ChoiceRow<int>(
            label: 'Starts quiet, gets louder over',
            value: a.rampSeconds,
            options: const <(int, String)>[
              (0, 'Off'),
              (15, '15 s'),
              (30, '30 s'),
              (60, '1 min'),
            ],
            onChanged: (int v) => _set(a.copyWith(rampSeconds: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lock the volume'),
            subtitle: const Text(
              'Turning it down while it rings puts it straight back up',
            ),
            value: a.volumeLock,
            onChanged: (bool v) => _set(a.copyWith(volumeLock: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vibrate'),
            value: a.vibrate,
            onChanged: (bool v) => _set(a.copyWith(vibrate: v)),
          ),

          section('To turn it off'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final AlarmChallenge c in AlarmChallenge.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: a.challenge == c,
                  onSelected: (_) => _set(
                    a.copyWith(
                      challenge: c,
                      // Each challenge keeps its count inside its own range
                      // (sums 1-10, shakes 5-60).
                      challengeCount: switch (c) {
                        AlarmChallenge.shake => a.challengeCount.clamp(5, 60),
                        AlarmChallenge.math ||
                        AlarmChallenge.random => a.challengeCount.clamp(1, 10),
                        _ => a.challengeCount,
                      },
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.gapMd,
          if (a.challenge == AlarmChallenge.random) ...<Widget>[
            Text(
              'Each ring picks one at random: maths, typing or shaking. '
              'Shaking takes 5 shakes for every problem.',
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            AppSpacing.gapSm,
          ],
          if (a.challenge == AlarmChallenge.math ||
              a.challenge == AlarmChallenge.random) ...<Widget>[
            _Stepper(
              label: 'Problems to solve',
              value: a.challengeCount,
              min: 1,
              max: 10,
              onChanged: (int v) => _set(a.copyWith(challengeCount: v)),
            ),
            AppSpacing.gapSm,
            SegmentedButton<MathDifficulty>(
              showSelectedIcon: false,
              segments: <ButtonSegment<MathDifficulty>>[
                for (final MathDifficulty d in MathDifficulty.values)
                  ButtonSegment<MathDifficulty>(value: d, label: Text(d.label)),
              ],
              selected: <MathDifficulty>{a.difficulty},
              onSelectionChanged: (Set<MathDifficulty> s) =>
                  _set(a.copyWith(difficulty: s.first)),
            ),
            AppSpacing.gapXs,
            Text(
              'Like ${a.difficulty.example}. A wrong answer gives you a new '
              'problem.',
              style: text.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontFeatures: _tabular,
              ),
            ),
          ],
          if (a.challenge == AlarmChallenge.type ||
              a.challenge == AlarmChallenge.random)
            TextField(
              controller: _phrase,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Sentence to type',
                hintText: defaultAlarmPhrase,
                helperText: 'Typed exactly, with suggestions off',
              ),
            ),
          if (a.challenge == AlarmChallenge.shake)
            _Stepper(
              label: 'Hard shakes',
              value: a.challengeCount,
              min: 5,
              max: 60,
              step: 5,
              onChanged: (int v) => _set(a.copyWith(challengeCount: v)),
            ),

          section('Snooze'),
          _ChoiceRow<int>(
            label: 'Snoozes allowed',
            value: a.snoozeLimit,
            options: const <(int, String)>[
              (0, 'None'),
              (1, '1'),
              (2, '2'),
              (3, '3'),
            ],
            onChanged: (int v) => _set(a.copyWith(snoozeLimit: v)),
          ),
          if (a.snoozeLimit > 0)
            _ChoiceRow<int>(
              label: 'Snooze length',
              value: a.snoozeMinutes,
              options: const <(int, String)>[
                (3, '3 min'),
                (5, '5 min'),
                (10, '10 min'),
              ],
              onChanged: (int v) => _set(a.copyWith(snoozeMinutes: v)),
            ),

          section('Wake-up check'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Make sure I stayed up'),
            subtitle: Text(
              '${a.wakeCheckMinutes} min after you turn it off, it asks '
              '"Still awake?". No answer within a minute and it rings again.',
            ),
            value: a.wakeCheck,
            onChanged: (bool v) => _set(a.copyWith(wakeCheck: v)),
          ),
          if (a.wakeCheck)
            _ChoiceRow<int>(
              label: 'Ask after',
              value: a.wakeCheckMinutes,
              options: const <(int, String)>[
                (3, '3 min'),
                (5, '5 min'),
                (10, '10 min'),
              ],
              onChanged: (int v) => _set(a.copyWith(wakeCheckMinutes: v)),
            ),

          AppSpacing.gapXl,
          SizedBox(
            height: AppSizes.buttonHeight,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save alarm'),
            ),
          ),
          AppSpacing.gapSm,
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Try it now'),
                  onPressed: () =>
                      ref.read(alarmControllerProvider.notifier).test(_current),
                ),
              ),
              if (!_isNew) ...<Widget>[
                AppSpacing.gapSm,
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: colors.error),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    onPressed: _delete,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // Sunday first, like the month grid. Bit 0 of the mask is Monday.
    const List<int> order = <int>[6, 0, 1, 2, 3, 4, 5];
    const List<String> letters = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const List<String> names = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final ColorScheme colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final int i in order)
          Semantics(
            label: names[i],
            selected: days & (1 << i) != 0,
            button: true,
            child: InkWell(
              borderRadius: AppRadius.medium,
              onTap: () => onChanged(days ^ (1 << i)),
              // A 48dp-tall tap area around the 40dp circle.
              child: SizedBox(
                height: AppSizes.minTouchTarget,
                child: Center(
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: days & (1 << i) != 0
                          ? colors.primary
                          : Colors.transparent,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text(
                      letters[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: days & (1 << i) != 0
                            ? colors.onPrimary
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(label),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            valueLabel,
            textAlign: TextAlign.end,
            style: const TextStyle(fontFeatures: _tabular),
          ),
        ),
      ],
    );
  }
}

/// A label with a short row of choices under it.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final (T v, String name) in options)
                ChoiceChip(
                  label: Text(name),
                  selected: v == value,
                  onSelected: (_) => onChanged(v),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        IconButton(
          tooltip: 'Fewer',
          icon: const Icon(Icons.remove_rounded),
          onPressed: value - step < min ? null : () => onChanged(value - step),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 32),
          child: Text(
            '$value',
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
