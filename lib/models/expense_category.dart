import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  shopping,
  study,
  transport,
  entertainment,
  utilities,
  other,
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Ăn uống (F&B)';
      case ExpenseCategory.shopping:
        return 'Mua sắm & Siêu thị';
      case ExpenseCategory.study:
        return 'Học tập & Giáo trình';
      case ExpenseCategory.transport:
        return 'Di chuyển & Xăng xe';
      case ExpenseCategory.entertainment:
        return 'Giải trí & Hoạt động';
      case ExpenseCategory.utilities:
        return 'Sinh hoạt & Hóa đơn';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.study:
        return Icons.menu_book_rounded;
      case ExpenseCategory.transport:
        return Icons.two_wheeler_rounded;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports_rounded;
      case ExpenseCategory.utilities:
        return Icons.bolt_rounded;
      case ExpenseCategory.other:
        return Icons.receipt_long_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFF97316); // Orange
      case ExpenseCategory.shopping:
        return const Color(0xFFEC4899); // Pink
      case ExpenseCategory.study:
        return const Color(0xFF3B82F6); // Electric Blue (VKU)
      case ExpenseCategory.transport:
        return const Color(0xFF10B981); // Emerald
      case ExpenseCategory.entertainment:
        return const Color(0xFF8B5CF6); // Purple
      case ExpenseCategory.utilities:
        return const Color(0xFFEAB308); // Amber
      case ExpenseCategory.other:
        return const Color(0xFF6B7280); // Gray
    }
  }

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.other;
    final lower = value.toLowerCase();
    for (final cat in ExpenseCategory.values) {
      if (cat.name.toLowerCase() == lower || cat.displayName.toLowerCase() == lower) {
        return cat;
      }
    }
    return ExpenseCategory.other;
  }
}
