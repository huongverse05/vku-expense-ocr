import 'expense_category.dart';

class ExpenseItem {
  final String id;
  final String merchant;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? receiptImagePath;
  final String? rawOcrText;
  final String? notes;
  final DateTime createdAt;

  const ExpenseItem({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.date,
    this.receiptImagePath,
    this.rawOcrText,
    this.notes,
    required this.createdAt,
  });

  ExpenseItem copyWith({
    String? id,
    String? merchant,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? receiptImagePath,
    String? rawOcrText,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'receipt_image_path': receiptImagePath,
      'raw_ocr_text': rawOcrText,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as String,
      merchant: map['merchant'] as String? ?? 'Không xác định',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategoryExt.fromString(map['category'] as String?),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      receiptImagePath: map['receipt_image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
