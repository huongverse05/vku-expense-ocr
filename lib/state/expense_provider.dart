import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';
import '../services/database_service.dart';

/// Quản lý state danh sách chi tiêu (Riverpod Notifier)
class ExpenseNotifier extends Notifier<List<ExpenseItem>> {
  @override
  List<ExpenseItem> build() {
    _loadFromDatabase();
    return const [];
  }

  Future<void> _loadFromDatabase() async {
    final list = await ExpenseDatabase.instance.getAllExpenses();
    state = list;
  }

  Future<void> addExpense(ExpenseItem item) async {
    await ExpenseDatabase.instance.insertExpense(item);
    state = [item, ...state];
  }

  Future<void> updateExpense(ExpenseItem item) async {
    await ExpenseDatabase.instance.updateExpense(item);
    state = [
      for (final exp in state)
        if (exp.id == item.id) item else exp,
    ];
  }

  Future<void> deleteExpense(String id) async {
    await ExpenseDatabase.instance.deleteExpense(id);
    state = state.where((exp) => exp.id != id).toList();
  }

  Future<void> reload() async {
    await _loadFromDatabase();
  }
}

/// Global compile-time safe Riverpod provider
final expenseProvider = NotifierProvider<ExpenseNotifier, List<ExpenseItem>>(
  ExpenseNotifier.new,
);

/// Active category filter provider
final selectedCategoryFilterProvider = StateProvider<ExpenseCategory?>((ref) => null);

/// Search keyword query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Theme mode provider (Light / Dark / System)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Filtered expenses reactive provider
final filteredExpensesProvider = Provider<List<ExpenseItem>>((ref) {
  final all = ref.watch(expenseProvider);
  final catFilter = ref.watch(selectedCategoryFilterProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return all.where((item) {
    if (catFilter != null && item.category != catFilter) {
      return false;
    }
    if (query.isNotEmpty) {
      final inMerchant = item.merchant.toLowerCase().contains(query);
      final inNotes = (item.notes ?? '').toLowerCase().contains(query);
      final inCategory = item.category.displayName.toLowerCase().contains(query);
      if (!inMerchant && !inNotes && !inCategory) {
        return false;
      }
    }
    return true;
  }).toList();
});

/// Total amount computation provider
final totalExpenseProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseProvider);
  return expenses.fold<double>(0.0, (acc, item) => acc + item.amount);
});

/// Total amount by category provider (used for Donut Chart)
final categoryTotalsProvider = Provider<Map<ExpenseCategory, double>>((ref) {
  final expenses = ref.watch(expenseProvider);
  final Map<ExpenseCategory, double> result = {};

  for (final cat in ExpenseCategory.values) {
    result[cat] = 0.0;
  }

  for (final exp in expenses) {
    result[exp.category] = (result[exp.category] ?? 0.0) + exp.amount;
  }

  return result;
});
