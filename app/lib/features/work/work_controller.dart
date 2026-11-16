import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/finance_controller.dart';
import '../finance/transaction.dart';
import 'shift.dart';
import 'work_repository.dart';

/// Every logged shift, earliest first.
class WorkController extends AsyncNotifier<List<Shift>> {
  WorkRepository get _repo => ref.read(workRepositoryProvider);

  @override
  FutureOr<List<Shift>> build() => _repo.getShifts();

  Future<void> _reload() async {
    state = await AsyncValue.guard(_repo.getShifts);
  }

  Future<void> addShifts(List<Shift> shifts) async {
    await _repo.createShifts(shifts);
    await _reload();
  }

  Future<void> deleteShift(Shift shift, {bool andLater = false}) async {
    if (andLater) {
      await _repo.deleteShiftAndLater(shift);
    } else {
      await _repo.deleteShift(shift.id);
    }
    await _reload();
  }

  /// Records [amount] as income received for the shifts worked so far and
  /// marks those shifts paid. Money only enters the balance here, when it
  /// has really arrived.
  Future<void> gotPaid(double amount, {DateTime? now}) async {
    final DateTime at = now ?? DateTime.now();
    final List<Shift> worked = <Shift>[
      for (final Shift shift in state.value ?? await _repo.getShifts())
        if (!shift.paid && shift.isWorked(at)) shift,
    ];
    if (worked.isEmpty) return;
    final int minutes = worked.fold(
      0,
      (int sum, Shift s) => sum + s.paidMinutes,
    );
    final Set<String> jobs = <String>{for (final Shift s in worked) s.job};
    await _repo.markPaid(worked.map((Shift s) => s.id));
    await ref
        .read(financeControllerProvider.notifier)
        .addTransaction(
          Transaction(
            id: 0,
            type: 'income',
            amount: amount,
            category: 'Part-time Job',
            occurredOn: at,
            note: '${formatHours(minutes)} hrs at ${jobs.join(', ')}',
          ),
        );
    await _reload();
  }
}

final AsyncNotifierProvider<WorkController, List<Shift>>
workControllerProvider = AsyncNotifierProvider<WorkController, List<Shift>>(
  WorkController.new,
);
