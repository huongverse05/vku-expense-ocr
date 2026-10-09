import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'router.dart';
import 'services/database_service.dart';
import 'state/expense_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database singleton and seed default data if first launch
  try {
    await ExpenseDatabase.instance.getAllExpenses();
  } catch (e) {
    debugPrint('Database initialization warning: $e');
  }

  runApp(
    // Khởi tạo ProviderScope cho Riverpod
    const ProviderScope(
      child: VkuExpenseOcrApp(),
    ),
  );
}

class VkuExpenseOcrApp extends ConsumerWidget {
  const VkuExpenseOcrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'VKU Receipt OCR & Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
