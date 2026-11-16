import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Asks how much money to keep aside for fixed bills. Returns the amount
/// (zero to stop setting anything aside), or null when cancelled.
Future<double?> showReserveDialog(
  BuildContext context, {
  required double current,
}) {
  return showDialog<double>(
    context: context,
    builder: (BuildContext ctx) => _ReserveDialog(current: current),
  );
}

class _ReserveDialog extends StatefulWidget {
  const _ReserveDialog({required this.current});

  final double current;

  @override
  State<_ReserveDialog> createState() => _ReserveDialogState();
}

class _ReserveDialogState extends State<_ReserveDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.current > 0
        ? widget.current.toStringAsFixed(
            widget.current == widget.current.roundToDouble() ? 0 : 2,
          )
        : '',
  );
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final String text = _amount.text.trim();
    final double? amount = text.isEmpty ? 0 : double.tryParse(text);
    if (amount == null || amount < 0) {
      setState(() => _error = 'Enter an amount, or leave it empty');
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set aside for bills'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Money you must not spend: fare, laundry, fees. It is taken off '
            'before the rest is spread over your days.',
          ),
          AppSpacing.gapLg,
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '₱ ',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
