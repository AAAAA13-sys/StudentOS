import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'goals_repository.dart';
import 'savings_goal.dart';

/// The views inside the Finance tab: Cashflow, Goals, and IOUs.
enum FinanceView { cashflow, goals, ious }

/// Which view of the Finance tab is showing (`Cashflow` by default).
final NotifierProvider<FinanceViewController, FinanceView> financeViewProvider =
    NotifierProvider<FinanceViewController, FinanceView>(
      FinanceViewController.new,
    );

class FinanceViewController extends Notifier<FinanceView> {
  @override
  FinanceView build() => FinanceView.cashflow;

  void show(FinanceView view) => state = view;
}

class GoalsController extends AsyncNotifier<List<SavingsGoal>> {
  GoalsRepository get _repo => ref.read(goalsRepositoryProvider);

  @override
  FutureOr<List<SavingsGoal>> build() => _repo.getGoals();

  Future<void> _reload() async {
    state = await AsyncValue.guard(_repo.getGoals);
  }

  Future<void> addGoal(SavingsGoal goal) async {
    await _repo.createGoal(goal);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    await _repo.updateGoal(goal);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> deleteGoal(int id) async {
    await _repo.deleteGoal(id);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> adjustSaved(int id, int deltaCents) async {
    await _repo.adjustSaved(id, deltaCents);
    if (!ref.mounted) return;
    await _reload();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.getGoals);
  }
}

final AsyncNotifierProvider<GoalsController, List<SavingsGoal>>
goalsControllerProvider =
    AsyncNotifierProvider<GoalsController, List<SavingsGoal>>(
      GoalsController.new,
    );
