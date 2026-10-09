import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

void main() {
  group('ReceiptParser Tests', () {
    test('Should parse Highlands Coffee receipt correctly', () {
      const sample = '''HIGHLANDS COFFEE - KHU V VKU
Địa chỉ: Đường Nam Kỳ Khởi Nghĩa, Ngũ Hành Sơn, Đà Nẵng
Ngày: 08/10/2026 10:15
Bàn: 04 - Thu ngân: HuongTT

1. Phin Sữa Đá (L)          39,000
2. Freeze Trà Xanh (M)      55,000
3. Bánh Mì Que Gà Cay       19,000

Cộng tiền hàng:            113,000
Thuế VAT (8%):               9,040
TỔNG CỘNG:                 122,000 đ
Phương thức: MoMo''';

      final result = ReceiptParser.parse(sample);

      expect(result.merchantName, contains('Highlands Coffee'));
      expect(result.totalAmount, 122000.0);
      expect(result.date, DateTime(2026, 10, 8));
      expect(result.category, ExpenseCategory.food);
      expect(result.confidenceScore, greaterThanOrEqualTo(0.8));
    });

    test('Should parse Căn tin VKU receipt correctly', () {
      const sample = '''CĂN TIN KHU V - ĐẠI HỌC VKU
HÓA ĐƠN BÁN LẺ
Ngày: 07/10/2026 11:45
Khách hàng: Sinh viên VKU (23IT117)

1. Cơm gà chiên nước mắm    30,000
2. Nước mía đá               7,000
3. Canh thêm                 3,000

TỔNG TIỀN:                  40,000 đ
Thanh toán: Tiền mặt''';

      final result = ReceiptParser.parse(sample);

      expect(result.merchantName?.toLowerCase(), contains('căn tin'));
      expect(result.totalAmount, 40000.0);
      expect(result.date, DateTime(2026, 10, 7));
      expect(result.category, ExpenseCategory.food);
    });

    test('Should parse Fahasa bookstore receipt with discount', () {
      const sample = '''NHÀ SÁCH FAHASA ĐÀ NẴNG
HÓA ĐƠN BÁN HÀNG
Ngày: 05/10/2026
Mã GD: FAH-2026-9923

1. Giáo trình Phát triển Đa nền tảng    145,000
2. Sổ tay ghi chép B5                    28,000
3. Bộ bút highlight Pastel (5 cây)       42,000

Tổng cộng:                             215,000 đ
Chiết khấu SV:                         -15,000
THANH TOÁN:                            200,000 VNĐ''';

      final result = ReceiptParser.parse(sample);

      expect(result.merchantName, contains('Fahasa'));
      expect(result.totalAmount, 200000.0);
      expect(result.date, DateTime(2026, 10, 5));
      expect(result.category, ExpenseCategory.study);
    });

    test('Should handle lowercase without diacritics', () {
      const sample = '''CIRCLE K
ngay: 06/10/2026
tong tien: 46000 vnd''';

      final result = ReceiptParser.parse(sample);

      expect(result.merchantName, 'Circle K');
      expect(result.totalAmount, 46000.0);
      expect(result.date, DateTime(2026, 10, 6));
      expect(result.category, ExpenseCategory.shopping);
    });
  });
}
