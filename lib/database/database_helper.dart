import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/diary_entry.dart';

class DiaryDatabaseHelper {
  static final DiaryDatabaseHelper instance = DiaryDatabaseHelper._init();
  static Database? _database;

  DiaryDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('daylog.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        content TEXT NOT NULL,
        mood_emoji TEXT NOT NULL,
        image_path TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_diaries_date ON diaries(date)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE diaries ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<int> insert(DiaryEntry entry) async {
    final db = await database;
    return await db.insert('diaries', entry.toMap());
  }

  Future<DiaryEntry?> getByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'diaries',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DiaryEntry.fromMap(maps.first);
  }

  Future<List<DiaryEntry>> getByMonth(int year, int month) async {
    final db = await database;
    final monthStr = '$year-${month.toString().padLeft(2, '0')}%';
    final maps = await db.query(
      'diaries',
      where: 'date LIKE ?',
      whereArgs: [monthStr],
      orderBy: 'date DESC',
    );
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  Future<List<DiaryEntry>> getAll() async {
    final db = await database;
    final maps = await db.query(
      'diaries',
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  Future<List<DiaryEntry>> getByWeek(int year, int month, int day) async {
    final db = await database;
    final now = DateTime(year, month, day);
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final startStr =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    final endStr =
        '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'diaries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );
    return maps.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  Future<int> update(DiaryEntry entry) async {
    final db = await database;
    return await db.update(
      'diaries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      'diaries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> initialize() async {
    await database;
  }
}
