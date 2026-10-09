import '../models/expense_category.dart';
import '../models/parsed_receipt.dart';

class ReceiptParser {
  /// Parser bóc tách thông tin hóa đơn từ văn bản OCR
  static ParsedReceipt parse(String rawText, {String? imagePath}) {
    final cleaned = rawText.trim();
    if (cleaned.isEmpty) {
      return ParsedReceipt(
        rawText: rawText,
        confidenceScore: 0.0,
        imagePath: imagePath,
      );
    }

    final lines = cleaned
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final total = extractTotal(cleaned, lines);
    final date = extractDate(cleaned, lines);
    final merchant = extractMerchant(cleaned, lines);
    final category = guessCategory(merchant, cleaned);

    double score = 0.0;
    if (total != null && total > 0) score += 0.45;
    if (merchant != null && merchant.isNotEmpty) score += 0.35;
    if (date != null) score += 0.20;

    return ParsedReceipt(
      merchantName: merchant,
      totalAmount: total,
      date: date,
      category: category,
      rawText: rawText,
      confidenceScore: double.parse(score.toStringAsFixed(2)),
      detectedLines: lines,
      imagePath: imagePath,
    );
  }

  /// Extracts total monetary amount from receipt text using tuned Regex heuristics
  static double? extractTotal(String rawText, [List<String>? preSplitLines]) {
    final lines = preSplitLines ??
        rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    // 1. Vietnamese & English Total Keywords regex (normalized without diacritics too)
    final keywordPattern = RegExp(
      r'(t[oổ]ng\s*(?:ti[eề]n|c[oộ]ng|thanh\s*to[aá]n)?|thanh\s*to[aá]n|c[oộ]ng\s*ti[eề]n\s*h[aà]ng|amount\s*due|total|grand\s*total|ph[aả]i\s*tr[aả]|ti[eề]n\s*m[aặ]t|s[oố]\s*ti[eề]n|tong\s*tien|tong\s*cong)',
      caseSensitive: false,
    );

    // Number pattern matching Vietnamese/Intl currency: 150.000, 150,000, 150000, 1,250.00
    final numberPattern = RegExp(r'[\d]{1,3}(?:[.,]\d{3})*(?:\.\d{2})?|\b\d{4,9}\b');

    // Strategy A: Scan lines matching keywords
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      if (keywordPattern.hasMatch(line)) {
        final matches = numberPattern.allMatches(line);
        if (matches.isNotEmpty) {
          final matchedStr = matches.last.group(0)!;
          final parsed = _sanitizeAndParseNumber(matchedStr);
          if (parsed != null && parsed >= 1000) {
            return parsed;
          }
        }

        // Look-ahead: sometimes amount is on the next line
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          final nextMatches = numberPattern.allMatches(nextLine);
          if (nextMatches.isNotEmpty) {
            final parsed = _sanitizeAndParseNumber(nextMatches.first.group(0)!);
            if (parsed != null && parsed >= 1000) {
              return parsed;
            }
          }
        }
      }
    }

    // Strategy B: Fallback - Scan for lines containing currency tags (VNĐ, đ, VND)
    final currencyTagPattern = RegExp(r'(\d[\d.,]*)\s*(?:vn[dđ]|đ|\$)', caseSensitive: false);
    for (int i = lines.length - 1; i >= 0; i--) {
      final match = currencyTagPattern.firstMatch(lines[i]);
      if (match != null) {
        final parsed = _sanitizeAndParseNumber(match.group(1)!);
        if (parsed != null && parsed >= 1000) {
          return parsed;
        }
      }
    }

    // Strategy C: Fallback - Pick the largest realistic monetary amount in the lower half
    double maxAmount = 0.0;
    final lowerHalfStart = (lines.length * 0.4).floor();
    for (int i = lowerHalfStart; i < lines.length; i++) {
      final matches = numberPattern.allMatches(lines[i]);
      for (final m in matches) {
        final val = _sanitizeAndParseNumber(m.group(0)!);
        if (val != null && val > maxAmount && val < 100000000) {
          maxAmount = val;
        }
      }
    }

    return maxAmount >= 1000 ? maxAmount : null;
  }

  /// Extracts transaction date from receipt text
  static DateTime? extractDate(String rawText, [List<String>? preSplitLines]) {
    final lines = preSplitLines ?? rawText.split('\n');

    // Formats: dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy, yyyy-MM-dd
    final datePattern1 = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})');
    final datePattern2 = RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})');
    final datePattern3 = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2})\b');

    for (final line in lines) {
      // Pattern 1: dd/MM/yyyy
      final match1 = datePattern1.firstMatch(line);
      if (match1 != null) {
        try {
          final day = int.parse(match1.group(1)!);
          final month = int.parse(match1.group(2)!);
          final year = int.parse(match1.group(3)!);
          if (_isValidDate(year, month, day)) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }

      // Pattern 2: yyyy-MM-dd
      final match2 = datePattern2.firstMatch(line);
      if (match2 != null) {
        try {
          final year = int.parse(match2.group(1)!);
          final month = int.parse(match2.group(2)!);
          final day = int.parse(match2.group(3)!);
          if (_isValidDate(year, month, day)) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }

      // Pattern 3: dd/MM/yy
      final match3 = datePattern3.firstMatch(line);
      if (match3 != null) {
        try {
          final day = int.parse(match3.group(1)!);
          final month = int.parse(match3.group(2)!);
          final shortYear = int.parse(match3.group(3)!);
          final year = 2000 + shortYear;
          if (_isValidDate(year, month, day)) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// Extracts store/merchant name from header lines
  static String? extractMerchant(String rawText, [List<String>? preSplitLines]) {
    final lines = preSplitLines ??
        rawText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    if (lines.isEmpty) return null;

    // Check for well-known Vietnamese brands first
    final knownMerchants = [
      'Highlands Coffee',
      'Phúc Long',
      'The Coffee House',
      'Circle K',
      'GS25',
      'WinMart',
      'VinMart',
      'FamilyMart',
      'Căn tin VKU Khu V',
      'Căn tin Khu A',
      'Nhà sách VKU',
      'Fahasa',
      'KFC',
      'Lotteria',
      'Jollibee',
      'Co.op Food',
      'Bách Hóa Xanh',
      'Trung Nguyên Legend',
      'Starbucks',
      'Mixue',
      '7-Eleven',
    ];

    for (final merchant in knownMerchants) {
      if (RegExp(merchant, caseSensitive: false).hasMatch(rawText)) {
        return merchant;
      }
    }

    // Generic header noise to skip
    final noisePattern = RegExp(
      r'^(h[oó]a\s*đ[oơ]n|phi[eế]u\s*thanh\s*to[aá]n|receipt|bill|invoice|vat|tax|c[uử]a\s*h[aà]ng|chi\s*nh[aá]nh|ng[aà]y|b[aà]n|thu\s*ng[aâ]n|tel|s[dđ]t|wifi|welcome|thanks)\b',
      caseSensitive: false,
    );

    // Scan top 6 lines for the best candidate
    final headerCandidates = lines.take(6).toList();
    for (final line in headerCandidates) {
      if (line.length >= 3 &&
          !noisePattern.hasMatch(line) &&
          !RegExp(r'^\d+$').hasMatch(line) &&
          !line.contains('http') &&
          !line.contains('www')) {
        return _formatMerchantName(line);
      }
    }

    return lines.isNotEmpty ? _formatMerchantName(lines.first) : 'Cửa hàng';
  }

  /// Automatically maps merchant & receipt content to ExpenseCategory
  static ExpenseCategory guessCategory(String? merchant, String rawText) {
    final combined = '${merchant ?? ''} $rawText'.toLowerCase();

    if (RegExp(r'(coffee|cafe|cà phê|trà sữa|tea|bánh mì|cơm|quán|phở|bún|gà rán|highlands|phúc long|lotteria|kfc|jollibee|ăn uống|căn tin|nhà hàng)').hasMatch(combined)) {
      return ExpenseCategory.food;
    }
    if (RegExp(r'(winmart|vinmart|circle k|gs25|coop|bách hóa|siêu thị|mart|tạp hóa|shopee|quần áo|thời trang|giày|store)').hasMatch(combined)) {
      return ExpenseCategory.shopping;
    }
    if (RegExp(r'(sách|giáo trình|vku|đại học|thư viện|học phí|in ấn|photocopy|fahasa|bút|vở|văn phòng phẩm)').hasMatch(combined)) {
      return ExpenseCategory.study;
    }
    if (RegExp(r'(grab|be|gojek|xăng|petrolimex|vé xe|xe buýt|bãi xe|gửi xe|rửa xe|honda|nhớt)').hasMatch(combined)) {
      return ExpenseCategory.transport;
    }
    if (RegExp(r'(cgv|lotte cinema|phim|bida|billiard|game|net|karaoke|vé xem|du lịch|resort)').hasMatch(combined)) {
      return ExpenseCategory.entertainment;
    }
    if (RegExp(r'(tiền điện|tiền nước|internet|viettel|fpt|vnpt|tiền nhà|phòng trọ|rác)').hasMatch(combined)) {
      return ExpenseCategory.utilities;
    }

    return ExpenseCategory.other;
  }

  static double? _sanitizeAndParseNumber(String str) {
    // Remove currency marks and spaces
    var clean = str.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (clean.isEmpty) return null;

    // Check if comma or dot is the thousands separator
    // In VN: 150.000 or 150,000 means 150000
    if (clean.contains('.') && clean.contains(',')) {
      final dotIndex = clean.indexOf('.');
      final commaIndex = clean.indexOf(',');
      if (dotIndex < commaIndex) {
        // 1.250,00 -> 1250.00
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // 1,250.00 -> 1250.00
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains('.')) {
      final parts = clean.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts.last.length == 3)) {
        // Thousands separator (150.000 or 1.250.000)
        clean = clean.replaceAll('.', '');
      }
    } else if (clean.contains(',')) {
      final parts = clean.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts.last.length == 3)) {
        // Thousands separator (150,000 or 1,250,000)
        clean = clean.replaceAll(',', '');
      } else {
        clean = clean.replaceAll(',', '.');
      }
    }

    return double.tryParse(clean);
  }

  static bool _isValidDate(int year, int month, int day) {
    if (year < 2020 || year > 2030) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    return true;
  }

  static String _formatMerchantName(String text) {
    final clean = text.replaceAll(RegExp(r'^[#*\-•\s]+|[#*\-•\s]+$'), '').trim();
    if (clean.isEmpty) return 'Cửa hàng';
    return clean;
  }
}
