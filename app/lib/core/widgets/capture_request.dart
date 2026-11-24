import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A capture sheet or view a home-screen widget or launcher shortcut asked for.
enum CaptureAction {
  addExpense,
  addNote,
  addEvent,
  addTask,
  openRecall;

  /// The Android route name (`add_expense`, `add_note`, `add_event`,
  /// `add_task`, `open_recall`), or null.
  static CaptureAction? fromRoute(String route) => switch (route) {
    'add_expense' => CaptureAction.addExpense,
    'add_note' => CaptureAction.addNote,
    'add_event' => CaptureAction.addEvent,
    'add_task' => CaptureAction.addTask,
    'open_recall' => CaptureAction.openRecall,
    _ => null,
  };
}

/// The capture waiting for its tab to open the sheet. Taken exactly once, so
/// a resume or rotation never reopens it.
final NotifierProvider<CaptureRequest, CaptureAction?> captureRequestProvider =
    NotifierProvider<CaptureRequest, CaptureAction?>(CaptureRequest.new);

class CaptureRequest extends Notifier<CaptureAction?> {
  @override
  CaptureAction? build() => null;

  void request(CaptureAction action) => state = action;

  /// Returns [action] if it is waiting, and clears it.
  bool take(CaptureAction action) {
    if (state != action) return false;
    state = null;
    return true;
  }
}

/// Runs [onCapture] once when [action] is requested: at once if the tab is
/// already built, or right after its first frame on a cold start.
class CaptureListener extends ConsumerStatefulWidget {
  const CaptureListener({
    required this.action,
    required this.onCapture,
    required this.child,
    super.key,
  });

  final CaptureAction action;
  final VoidCallback onCapture;
  final Widget child;

  @override
  ConsumerState<CaptureListener> createState() => _CaptureListenerState();
}

class _CaptureListenerState extends ConsumerState<CaptureListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRun());
  }

  void _maybeRun() {
    if (!mounted) return;
    if (ref.read(captureRequestProvider.notifier).take(widget.action)) {
      widget.onCapture();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CaptureAction?>(captureRequestProvider, (_, CaptureAction? a) {
      if (a == widget.action) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRun());
      }
    });
    return widget.child;
  }
}
