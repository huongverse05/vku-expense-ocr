import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';
import '../models/parsed_receipt.dart';
import '../state/expense_provider.dart';

/// Màn hình kiểm tra và hiệu chỉnh dữ liệu sau khi quét OCR
class ReviewVerificationScreen extends ConsumerStatefulWidget {
  final ParsedReceipt parsedReceipt;

  const ReviewVerificationScreen({
    super.key,
    required this.parsedReceipt,
  });

  @override
  ConsumerState<ReviewVerificationScreen> createState() =>
      _ReviewVerificationScreenState();
}

class _ReviewVerificationScreenState
    extends ConsumerState<ReviewVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  bool _showRawOcr = false;

  @override
  void initState() {
    super.initState();
    final data = widget.parsedReceipt;

    _merchantController = TextEditingController(
      text: data.merchantName ?? '',
    );

    // Format amount into clean string for editing
    final amountVal = data.totalAmount != null
        ? data.totalAmount!.round().toString()
        : '';
    _amountController = TextEditingController(text: amountVal);

    _notesController = TextEditingController(
      text: 'Quét tự động từ hóa đơn qua Google ML Kit',
    );

    _selectedCategory = data.category;
    _selectedDate = data.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitAndCommit() {
    if (!_formKey.currentState!.validate()) return;

    final merchant = _merchantController.text.trim();
    final rawAmountStr = _amountController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final amount = double.tryParse(rawAmountStr) ?? 0.0;
    final notes = _notesController.text.trim();

    final newExpense = ExpenseItem(
      id: const Uuid().v4(),
      merchant: merchant,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      receiptImagePath: widget.parsedReceipt.imagePath,
      rawOcrText: widget.parsedReceipt.rawText,
      notes: notes.isNotEmpty ? notes : null,
      createdAt: DateTime.now(),
    );

    // Commit to Riverpod State & SQLite DB (Slide 28 Week 8)
    ref.read(expenseProvider.notifier).addExpense(newExpense);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã lưu hóa đơn "$merchant" (${Formatters.formatCurrency(amount)}) vào SQLite!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.emeraldGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Navigate back to home/dashboard
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = widget.parsedReceipt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra & Xác thực Hóa đơn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card with OCR status & Confidence
              Card(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.electricBlue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: AppTheme.electricBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kết quả nhận dạng OCR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vui lòng đối chiếu và sửa lại nếu AI nhận diện chưa đúng.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: data.confidenceScore >= 0.8
                              ? AppTheme.emeraldGreen.withOpacity(0.15)
                              : AppTheme.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: data.confidenceScore >= 0.8
                                ? AppTheme.emeraldGreen
                                : AppTheme.accentGold,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${(data.confidenceScore * 100).toInt()}% tin cậy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: data.confidenceScore >= 0.8
                                ? AppTheme.emeraldGreen
                                : AppTheme.accentGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Image preview if available
              if (data.imagePath != null && !kIsWeb && File(data.imagePath!).existsSync())
                Container(
                  height: 140,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(data.imagePath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Form Field 1: Merchant / Store Name
              Text(
                'Tên Cửa Hàng / Đơn Vị Phát Hành',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  hintText: 'VD: Highlands Coffee, Căn tin VKU...',
                  prefixIcon: Icon(Icons.store_rounded, color: AppTheme.electricBlue),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên cửa hàng'
                    : null,
              ),

              const SizedBox(height: 16),

              // Form Field 2: Total Amount
              Text(
                'Tổng Tiền Thanh Toán (VNĐ)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'VD: 122000',
                  prefixIcon: Icon(Icons.payments_rounded, color: AppTheme.accentGold),
                  suffixText: 'VNĐ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền';
                  final clean = v.replaceAll(RegExp(r'[^\d.]'), '');
                  final val = double.tryParse(clean);
                  if (val == null || val <= 0) return 'Số tiền phải lớn hơn 0';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Form Field 3: Date Picker & Category Dropdown (in a Row)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày Giao Dịch',
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.electricBlue),
                            ),
                            child: Text(
                              Formatters.formatDate(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danh Mục Chi Tiêu',
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<ExpenseCategory>(
                          initialValue: _selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              _selectedCategory.icon,
                              color: _selectedCategory.color,
                            ),
                          ),
                          items: ExpenseCategory.values.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat.displayName,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (cat) {
                            if (cat != null) setState(() => _selectedCategory = cat);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Form Field 4: Notes
              Text(
                'Ghi Chú Chi Tiêu',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'VD: Ăn trưa cùng nhóm đồ án...',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),

              const SizedBox(height: 16),

              // Collapsible Raw OCR View
              Card(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ExpansionTile(
                  initiallyExpanded: _showRawOcr,
                  title: const Text(
                    'Xem văn bản gốc OCR (Raw ML Kit Text)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: double.infinity,
                        child: SelectableText(
                          data.rawText.isNotEmpty ? data.rawText : '(Không có văn bản)',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Commit to SQLite Button
              ElevatedButton.icon(
                onPressed: _submitAndCommit,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Xác nhận & Lưu vào SQLite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Discard / Retake Button
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Hủy & Quét Lại'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
