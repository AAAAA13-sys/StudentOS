import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bill.dart';
import 'bills_repository.dart';
import 'finance_controller.dart';
import 'transaction.dart';

/// Manages recurring bills, manual 1-tap logging, and idempotent auto-logging
/// for bills marked `autoLog` when due.
class BillsController extends AsyncNotifier<List<Bill>> {
  BillsRepository get _repo => ref.read(billsRepositoryProvider);

  @override
  FutureOr<List<Bill>> build() async {
    final List<Bill> bills = await _repo.getBills();
    return _autoLogDueBills(bills, DateTime.now());
  }

  Future<void> _reload() async {
    state = await AsyncValue.guard(_repo.getBills);
  }

  Future<List<Bill>> _autoLogDueBills(List<Bill> bills, DateTime now) async {
    final DateTime today = dateOnly(now);
    bool loggedAny = false;
    for (final Bill bill in bills) {
      if (!bill.active || !bill.autoLog || !bill.isDueOnOrBefore(today)) {
        continue;
      }
      await _recordAndAdvance(bill, today);
      loggedAny = true;
      if (!ref.mounted) return const <Bill>[];
    }
    return loggedAny ? await _repo.getBills() : bills;
  }

  Future<void> _recordAndAdvance(Bill bill, DateTime today) async {
    final DateTime next = nextDueAfter(bill.schedule, today);
    // Advance nextDueOn before inserting the expense so a later load never
    // double-logs the same cycle.
    await _repo.updateBill(bill.copyWith(nextDueOn: formatDateKey(next)));
    await ref
        .read(financeControllerProvider.notifier)
        .addTransaction(
          Transaction(
            id: 0,
            type: 'expense',
            amount: bill.amount,
            category: bill.category,
            occurredOn: today,
            note: bill.title,
          ),
        );
  }

  Future<void> addBill(Bill bill) async {
    await _repo.createBill(bill);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> updateBill(Bill bill) async {
    await _repo.updateBill(bill);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> deleteBill(int id) async {
    await _repo.deleteBill(id);
    if (!ref.mounted) return;
    await _reload();
  }

  /// Logs [bill] as today's expense and advances `nextDueOn` to the next
  /// cycle after today.
  Future<void> logBill(Bill bill, {DateTime? now}) async {
    final DateTime today = dateOnly(now ?? DateTime.now());
    await _recordAndAdvance(bill, today);
    if (!ref.mounted) return;
    await _reload();
  }

  /// Logs every active bill whose `nextDueOn` is on or before today.
  Future<void> logAllDue({DateTime? now}) async {
    final DateTime today = dateOnly(now ?? DateTime.now());
    final List<Bill> all = state.value ?? await _repo.getBills();
    final List<Bill> due = <Bill>[
      for (final Bill bill in all)
        if (bill.isDueOnOrBefore(today)) bill,
    ];
    if (due.isEmpty) return;
    for (final Bill bill in due) {
      await _recordAndAdvance(bill, today);
      if (!ref.mounted) return;
    }
    await _reload();
  }
}

final AsyncNotifierProvider<BillsController, List<Bill>>
billsControllerProvider = AsyncNotifierProvider<BillsController, List<Bill>>(
  BillsController.new,
);
