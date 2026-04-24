import '../models/todo.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // ================= DATABASE INIT =================

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'todo_database.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ================= CREATE TABLE =================

  Future<void> _onCreate(Database db, int version) async {
    // TABLE CATEGORY
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // TABLE TODO
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        createdAt TEXT,
        deadline TEXT,
        categoryId INTEGER,
        isDone INTEGER,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');
  }

  // ================= UPGRADE =================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // VERSION 2 → tambah deadline
    if (oldVersion < 2) {
      final tableInfo = await db.rawQuery("PRAGMA table_info(todos)");

      final deadlineExists = tableInfo.any((col) => col['name'] == 'deadline');

      if (!deadlineExists) {
        await db.execute('ALTER TABLE todos ADD COLUMN deadline TEXT');
      }
    }

    // VERSION 3 → tambah categoryId + table categories
    if (oldVersion < 3) {
      final tableInfo = await db.rawQuery("PRAGMA table_info(todos)");

      final categoryExists = tableInfo.any(
        (col) => col['name'] == 'categoryId',
      );

      if (!categoryExists) {
        await db.execute('ALTER TABLE todos ADD COLUMN categoryId INTEGER');
      }

      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');
    }
  }

  // =====================================================
  // ================= CATEGORY CRUD =====================
  // =====================================================

  Future<int> insertCategory(Category category) async {
    final db = await database;

    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;

    final maps = await db.query('categories', orderBy: 'name ASC');

    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;

    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;

    // biar todo yang pakai kategori ini tidak error
    await db.update(
      'todos',
      {'categoryId': null},
      where: 'categoryId = ?',
      whereArgs: [id],
    );

    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // =====================================================
  // ================= TODO + JOIN CATEGORY ==============
  // =====================================================

  Future<List<Map<String, dynamic>>> getTodosWithCategory({
    String? keyword,
    String filter = 'all',
    int? categoryId,
    bool sortByDeadline = false,
  }) async {
    final db = await database;

    List<String> conditions = [];
    List<dynamic> args = [];

    // FILTER STATUS
    if (filter == 'done') {
      conditions.add('t.isDone = 1');
    } else if (filter == 'undone') {
      conditions.add('t.isDone = 0');
    }

    // SEARCH TITLE
    if (keyword != null && keyword.isNotEmpty) {
      conditions.add('t.title LIKE ?');
      args.add('%$keyword%');
    }

    // FILTER CATEGORY
    if (categoryId != null) {
      conditions.add('t.categoryId = ?');
      args.add(categoryId);
    }

    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';

    // ORDER BY DINAMIS
    final orderBy = sortByDeadline
        ? '''
          ORDER BY
            CASE
              WHEN t.deadline IS NULL OR t.deadline = '' THEN 1
              ELSE 0
            END,
            t.deadline ASC
        '''
        : 'ORDER BY t.createdAt DESC';

    final result = await db.rawQuery('''
      SELECT
        t.*,
        c.name AS categoryName
      FROM todos t
      LEFT JOIN categories c
        ON t.categoryId = c.id
      $whereClause
      $orderBy
    ''', args);

    return result;
  }

  // =====================================================
  // ================= TODO CRUD =========================
  // =====================================================

  Future<int> insertTodo(Todo todo) async {
    final db = await database;

    return await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await database;

    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> toggleTodoStatus(int id, bool isDone) async {
    final db = await database;

    return await db.update(
      'todos',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;

    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
