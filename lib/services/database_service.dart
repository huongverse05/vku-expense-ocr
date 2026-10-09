import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense_category.dart';
import '../models/expense_item.dart';

class ExpenseDatabase {
  static final ExpenseDatabase instance = ExpenseDatabase._init();
  static Database? _database;

  // In-memory cache fallback for environments without native sqflite (like Web)
  final List<ExpenseItem> _memoryStore = [];

  ExpenseDatabase._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('vku_expenses.db');
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        receipt_image_path TEXT,
        raw_ocr_text TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertExpense(ExpenseItem item) async {
    if (kIsWeb) {
      _memoryStore.removeWhere((e) => e.id == item.id);
      _memoryStore.insert(0, item);
      return 1;
    }
    final db = await database;
    if (db == null) return 0;
    return await db.insert(
      'expenses',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ExpenseItem>> getAllExpenses() async {
    if (kIsWeb) {
      if (_memoryStore.isEmpty) {
        _populateMemoryDefaults();
      }
      return List.unmodifiable(_memoryStore);
    }

    final db = await database;
    if (db == null) return [];

    final result = await db.query(
      'expenses',
      orderBy: 'date DESC, created_at DESC',
    );

    if (result.isEmpty) {
      await seedInitialData();
      return getAllExpenses();
    }

    return result.map((json) => ExpenseItem.fromMap(json)).toList();
  }

  Future<ExpenseItem?> getExpenseById(String id) async {
    if (kIsWeb) {
      return _memoryStore.where((e) => e.id == id).firstOrNull;
    }
    final db = await database;
    if (db == null) return null;

    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ExpenseItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(ExpenseItem item) async {
    if (kIsWeb) {
      final idx = _memoryStore.indexWhere((e) => e.id == item.id);
      if (idx != -1) {
        _memoryStore[idx] = item;
        return 1;
      }
      return 0;
    }

    final db = await database;
    if (db == null) return 0;

    return await db.update(
      'expenses',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    if (kIsWeb) {
      _memoryStore.removeWhere((e) => e.id == id);
      return 1;
    }

    final db = await database;
    if (db == null) return 0;

    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<ExpenseCategory, double>> getCategoryTotals() async {
    final expenses = await getAllExpenses();
    final Map<ExpenseCategory, double> totals = {};

    for (final cat in ExpenseCategory.values) {
      totals[cat] = 0.0;
    }

    for (final exp in expenses) {
      totals[exp.category] = (totals[exp.category] ?? 0.0) + exp.amount;
    }

    return totals;
  }

  Future<double> getTotalAmount() async {
    final expenses = await getAllExpenses();
    return expenses.fold<double>(0.0, (acc, item) => acc + item.amount);
  }

  Future<void> seedInitialData() async {
    final samples = _getDefaultSeedItems();
    for (final item in samples) {
      await insertExpense(item);
    }
  }

  void _populateMemoryDefaults() {
    _memoryStore.addAll(_getDefaultSeedItems());
  }

  List<ExpenseItem> _getDefaultSeedItems() {
    final now = DateTime.now();
    return [
      ExpenseItem(
        id: 'vku_seed_01',
        merchant: 'Highlands Coffee - Khu V',
        amount: 122000,
        category: ExpenseCategory.food,
        date: now.subtract(const Duration(hours: 3)),
        rawOcrText: 'HIGHLANDS COFFEE - KHU V VKU\nTỔNG CỘNG: 122,000 đ',
        notes: 'Họp nhóm đồ án Đa nền tảng tại Khu V',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      ExpenseItem(
        id: 'vku_seed_02',
        merchant: 'Nhà sách Fahasa Đà Nẵng',
        amount: 200000,
        category: ExpenseCategory.study,
        date: now.subtract(const Duration(days: 1, hours: 2)),
        rawOcrText: 'NHÀ SÁCH FAHASA ĐÀ NẴNG\nTHANH TOÁN: 200,000 VNĐ',
        notes: 'Sách giáo trình Flutter & Reanimated',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ExpenseItem(
        id: 'vku_seed_03',
        merchant: 'Căn tin Khu V - VKU',
        amount: 40000,
        category: ExpenseCategory.food,
        date: now.subtract(const Duration(days: 2)),
        rawOcrText: 'CĂN TIN KHU V - ĐẠI HỌC VKU\nTỔNG TIỀN: 40,000 đ',
        notes: 'Cơm trưa sau buổi thực hành phòng Lab',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ExpenseItem(
        id: 'vku_seed_04',
        merchant: 'Circle K Nam Kỳ Khởi Nghĩa',
        amount: 46000,
        category: ExpenseCategory.shopping,
        date: now.subtract(const Duration(days: 3)),
        rawOcrText: 'CIRCLE K ĐÀ NẴNG\nTỔNG TIỀN: 46,000 đ',
        notes: 'Ăn nhẹ ôn thi giữa kỳ',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ExpenseItem(
        id: 'vku_seed_05',
        merchant: 'Cây xăng Petrolimex Hòa Hải',
        amount: 70000,
        category: ExpenseCategory.transport,
        date: now.subtract(const Duration(days: 4)),
        rawOcrText: 'PETROLIMEX\nTIỀN THANH TOÁN: 70,000 đ',
        notes: 'Đổ xăng xe máy đi học VKU',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      ExpenseItem(
        id: 'vku_seed_06',
        merchant: 'Rạp chiếu phim CGV Vincom',
        amount: 150000,
        category: ExpenseCategory.entertainment,
        date: now.subtract(const Duration(days: 5)),
        rawOcrText: 'CGV CINEMAS\nTOTAL: 150.000 VND',
        notes: 'Vé xem phim cuối tuần',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  Future<void> close() async {
    final db = await database;
    db?.close();
  }
}
