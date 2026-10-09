import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/parsed_receipt.dart';
import 'screens/main_shell_screen.dart';
import 'screens/review_verification_screen.dart';
import 'screens/scan_receipt_screen.dart';

/// Cấu hình điều hướng các màn hình trong ứng dụng
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShellScreen(initialIndex: 0),
    ),
    GoRoute(
      path: '/expenses',
      builder: (context, state) => const MainShellScreen(initialIndex: 1),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const MainShellScreen(initialIndex: 2),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanReceiptScreen(),
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) {
        final parsed = state.extra as ParsedReceipt? ??
            const ParsedReceipt(rawText: '');
        return ReviewVerificationScreen(parsedReceipt: parsed);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Trang không tồn tại: ${state.uri}'),
    ),
  ),
);
