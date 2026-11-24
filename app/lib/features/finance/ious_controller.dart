import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'finance_controller.dart';
import 'iou_item.dart';
import 'ious_repository.dart';
import 'transaction.dart';

/// Filter chips for the `Finance > IOUs` list.
enum IouFilter { open, owed, owing, settled }

class IousController extends AsyncNotifier<List<IouItem>> {
  IousRepository get _repo => ref.read(iousRepositoryProvider);

  @override
  FutureOr<List<IouItem>> build() => _repo.getIous();

  Future<void> _reload() async {
    state = await AsyncValue.guard(_repo.getIous);
  }

  Future<void> addIou(IouItem item) async {
    await _repo.createIou(item);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> updateIou(IouItem item) async {
    await _repo.updateIou(item);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> deleteIou(int id) async {
    await _repo.deleteIou(id);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> settleIou(
    IouItem item, {
    bool logInCashflow = false,
    DateTime? now,
  }) async {
    final DateTime settledAt = now ?? DateTime.now();
    await _repo.setSettled(item.id, settled: true, at: settledAt);
    if (!ref.mounted) return;
    if (logInCashflow) {
      final bool isOwed = item.direction == IouDirection.owed;
      final String baseNote = isOwed
          ? 'Settled IOU from ${item.person}'
          : 'Paid IOU to ${item.person}';
      final String? extra = item.note?.trim();
      final String fullNote = (extra != null && extra.isNotEmpty)
          ? '$baseNote · $extra'
          : baseNote;
      await ref
          .read(financeControllerProvider.notifier)
          .addTransaction(
            Transaction(
              id: 0,
              type: isOwed ? 'income' : 'expense',
              amount: item.amount,
              category: 'Other',
              occurredOn: DateTime(
                settledAt.year,
                settledAt.month,
                settledAt.day,
              ),
              note: fullNote,
            ),
          );
      if (!ref.mounted) return;
    }
    await _reload();
  }

  Future<void> reopenIou(IouItem item) async {
    await _repo.setSettled(item.id, settled: false);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.getIous);
  }
}

final AsyncNotifierProvider<IousController, List<IouItem>>
iousControllerProvider =
    AsyncNotifierProvider<IousController, List<IouItem>>(
      IousController.new,
    );
