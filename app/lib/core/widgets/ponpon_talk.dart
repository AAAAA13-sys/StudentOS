import 'package:flutter/material.dart';

import '../../features/insights/ponpon_insight.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'ponpon.dart';

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// A speech bubble whose tail points left, at Ponpon. The fill comes from the
/// theme; the outline is a hairline, never a shadow.
class _BubbleBorder extends ShapeBorder {
  const _BubbleBorder({required this.side});

  final BorderSide side;

  static const double tailWidth = 8;
  static const double tailHalfHeight = 6;
  static const double radius = 16;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final Path body = Path()
      ..addRRect(
        RRect.fromLTRBR(
          rect.left + tailWidth,
          rect.top,
          rect.right,
          rect.bottom,
          const Radius.circular(radius),
        ),
      );
    final double cy = rect.center.dy;
    final Path tail = Path()
      ..moveTo(rect.left + tailWidth + 1, cy - tailHalfHeight)
      ..lineTo(rect.left, cy)
      ..lineTo(rect.left + tailWidth + 1, cy + tailHalfHeight)
      ..close();
    return Path.combine(PathOperation.union, body, tail);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width
        ..color = side.color,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}

/// "Ponpon says": Ponpon on the left and a speech bubble with one insight.
/// Tap the bubble for the next one; the close button calls [onClose].
class PonponTalk extends StatefulWidget {
  const PonponTalk({
    required this.insights,
    required this.onClose,
    this.onAction,
    super.key,
  });

  final List<PonponInsight> insights;
  final VoidCallback onClose;

  /// Called when the small action button of a tip is pressed.
  final void Function(PonponAction action)? onAction;

  @override
  State<PonponTalk> createState() => _PonponTalkState();
}

class _PonponTalkState extends State<PonponTalk> {
  int _index = 0;

  void _next() {
    if (widget.insights.length < 2) return;
    setState(() => _index = (_index + 1) % widget.insights.length);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) return const SizedBox.shrink();
    final ColorScheme colors = context.colors;
    final int total = widget.insights.length;
    final int at = _index % total;
    final PonponInsight insight = widget.insights[at];
    final Duration fade = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final TextStyle? style = context.textStyles.bodyMedium?.copyWith(
      color: colors.onPrimaryContainer,
      fontFeatures: _tabular,
    );
    final ShapeBorder shape = _BubbleBorder(
      side: BorderSide(color: colors.outlineVariant, width: 0.75),
    );

    return Row(
      children: <Widget>[
        AnimatedSwitcher(
          duration: fade,
          switchInCurve: Curves.easeOutCubic,
          child: Ponpon(
            key: ValueKey<PonponMood>(insight.mood),
            mood: insight.mood,
            size: 48,
          ),
        ),
        Expanded(
          child: Semantics(
            container: true,
            button: total > 1,
            label: 'Ponpon says: ${insight.text}',
            value: total > 1 ? 'Tip ${at + 1} of $total' : null,
            hint: total > 1 ? 'Next tip' : null,
            onTap: total > 1 ? _next : null,
            child: Material(
              color: colors.primaryContainer,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: shape,
                onTap: total > 1 ? _next : null,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: _BubbleBorder.tailWidth + AppSpacing.md,
                    top: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: fade,
                          switchInCurve: Curves.easeOutCubic,
                          layoutBuilder:
                              (Widget? current, List<Widget> previous) => Stack(
                                alignment: Alignment.centerLeft,
                                children: <Widget>[...previous, ?current],
                              ),
                          child: Column(
                            key: ValueKey<String>(insight.text),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ExcludeSemantics(
                                child: Text(
                                  insight.text,
                                  style: style,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (insight.action != null &&
                                  widget.onAction != null)
                                _ActionButton(
                                  label: insight.action!.label,
                                  onPressed: () =>
                                      widget.onAction!(insight.action!),
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hide Ponpon tips',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: colors.onPrimaryContainer,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: widget.onClose,
                      ),
                    ],
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

/// The small text button inside a bubble. It is not wrapped in the bubble's
/// semantics (which are excluded for the text), so it announces itself.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: colors.onPrimaryContainer,
          minimumSize: const Size(AppSizes.minTouchTarget, 36),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
