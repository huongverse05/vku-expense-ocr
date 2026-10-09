import 'expense_category.dart';

class ParsedReceipt {
  final String? merchantName;
  final double? totalAmount;
  final DateTime? date;
  final ExpenseCategory category;
  final String rawText;
  final double confidenceScore;
  final List<String> detectedLines;
  final String? imagePath;

  const ParsedReceipt({
    this.merchantName,
    this.totalAmount,
    this.date,
    this.category = ExpenseCategory.other,
    required this.rawText,
    this.confidenceScore = 0.0,
    this.detectedLines = const [],
    this.imagePath,
  });

  bool get isComplete =>
      merchantName != null &&
      merchantName!.isNotEmpty &&
      totalAmount != null &&
      totalAmount! > 0;

  ParsedReceipt copyWith({
    String? merchantName,
    double? totalAmount,
    DateTime? date,
    ExpenseCategory? category,
    String? rawText,
    double? confidenceScore,
    List<String>? detectedLines,
    String? imagePath,
  }) {
    return ParsedReceipt(
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      category: category ?? this.category,
      rawText: rawText ?? this.rawText,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      detectedLines: detectedLines ?? this.detectedLines,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
