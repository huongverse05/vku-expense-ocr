import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../models/parsed_receipt.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen>
    with SingleTickerProviderStateMixin {
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  String _statusMessage = '';

  late final AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = source == ImageSource.camera
          ? 'Đang mở Camera chụp hóa đơn...'
          : 'Đang mở Thư viện chọn ảnh...';
    });

    try {
      final parsed = await _ocrService.captureAndScan(source: source);
      if (parsed != null && mounted) {
        _navigateToReview(parsed);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chụp ảnh/OCR: $e'),
            backgroundColor: AppTheme.alertCrimson,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
      }
    }
  }

  void _handleSampleReceipt(String title, String receiptText) {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Đang nhận diện mẫu hóa đơn: $title...';
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final parsed = ReceiptParser.parse(receiptText);
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      _navigateToReview(parsed);
    });
  }

  void _navigateToReview(ParsedReceipt parsed) {
    // Navigate to Review Screen passing parsed data
    context.push('/review', extra: parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Hóa Đơn (ML Kit OCR)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isProcessing
          ? _buildScanningOverlay(isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Camera / OCR Viewfinder Card
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.electricBlue.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Viewfinder Corner Brackets
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.electricBlue.withOpacity(0.6),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        // Scanner Beam Animation
                        AnimatedBuilder(
                          animation: _scanAnimController,
                          builder: (context, _) => Positioned(
                            top: 40 + (160 * _scanAnimController.value),
                            left: 32,
                            right: 32,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.electricBlue,
                                    AppTheme.accentGold,
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.electricBlue.withOpacity(0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Center icon and guidance text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.electricBlue.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.document_scanner_rounded,
                                size: 40,
                                color: AppTheme.electricBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Đặt hóa đơn ngay ngắn trong khung',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AI sẽ tự động đọc Tổng tiền, Ngày & Tên quán',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons: Camera & Gallery
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleCapture(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Chụp Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleCapture(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Chọn Ảnh'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppTheme.electricBlue, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Demo Sample Receipts (Tested on real VKU receipts)
                  Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, color: AppTheme.accentGold, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Mẫu Hóa Đơn Thử Nghiệm Nhanh (Demo Test)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bấm để thử nghiệm bóc tách Regex ngay lập tức không cần chụp ảnh thật:',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildSampleCard(
                    title: 'Highlands Coffee - Khu V (122.000 đ)',
                    subtitle: 'Hóa đơn cà phê nhóm đồ án VKU',
                    color: const Color(0xFFF97316),
                    icon: Icons.coffee_rounded,
                    onTap: () => _handleSampleReceipt(
                      'Highlands Coffee',
                      '''HIGHLANDS COFFEE - KHU V VKU
Địa chỉ: Đường Nam Kỳ Khởi Nghĩa, Ngũ Hành Sơn, Đà Nẵng
Ngày: 08/10/2026 10:15
Bàn: 04 - Thu ngân: HuongTT

1. Phin Sữa Đá (L)          39,000
2. Freeze Trà Xanh (M)      55,000
3. Bánh Mì Que Gà Cay       19,000

Cộng tiền hàng:            113,000
Thuế VAT (8%):               9,040
TỔNG CỘNG:                 122,000 đ
Phương thức: MoMo''',
                    ),
                  ),

                  _buildSampleCard(
                    title: 'Căn tin Khu V - Đại học VKU (40.000 đ)',
                    subtitle: 'Cơm trưa sinh viên ngành CNTT',
                    color: const Color(0xFF10B981),
                    icon: Icons.restaurant_rounded,
                    onTap: () => _handleSampleReceipt(
                      'Căn tin VKU',
                      '''CĂN TIN KHU V - ĐẠI HỌC VKU
HÓA ĐƠN BÁN LẺ
Ngày: 07/10/2026 11:45
Khách hàng: Sinh viên VKU (23IT117)

1. Cơm gà chiên nước mắm    30,000
2. Nước mía đá               7,000
3. Canh thêm                 3,000

TỔNG TIỀN:                  40,000 đ
Thanh toán: Tiền mặt''',
                    ),
                  ),

                  _buildSampleCard(
                    title: 'Nhà sách Fahasa Đà Nẵng (200.000 đ)',
                    subtitle: 'Giáo trình & Văn phòng phẩm học tập',
                    color: const Color(0xFF3B82F6),
                    icon: Icons.menu_book_rounded,
                    onTap: () => _handleSampleReceipt(
                      'Fahasa Đà Nẵng',
                      '''NHÀ SÁCH FAHASA ĐÀ NẴNG
HÓA ĐƠN BÁN HÀNG
Ngày: 05/10/2026
Mã GD: FAH-2026-9923

1. Giáo trình Phát triển Đa nền tảng    145,000
2. Sổ tay ghi chép B5                    28,000
3. Bộ bút highlight Pastel (5 cây)       42,000

Tổng cộng:                             215,000 đ
Chiết khấu SV:                         -15,000
THANH TOÁN:                            200,000 VNĐ''',
                    ),
                  ),

                  _buildSampleCard(
                    title: 'Circle K Nam Kỳ Khởi Nghĩa (46.000 đ)',
                    subtitle: 'Tiện lợi mua sắm ăn nhẹ',
                    color: const Color(0xFFEC4899),
                    icon: Icons.storefront_rounded,
                    onTap: () => _handleSampleReceipt(
                      'Circle K',
                      '''CIRCLE K ĐÀ NẴNG
PHIẾU THANH TOÁN
Ngày: 06/10/2026 21:30

1. Bánh bao trứng cút       15,000
2. Sữa đậu nành Fami         9,000
3. Mì trộn Indomie thập cẩm 22,000

TỔNG TIỀN:                  46,000 đ
Cảm ơn quý khách!''',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSampleCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }

  Widget _buildScanningOverlay(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.electricBlue,
              strokeWidth: 4,
            ),
            const SizedBox(height: 24),
            Text(
              'Đang xử lý nhận diện On-Device OCR...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
