import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/diary_entry.dart';
import '../models/bottle.dart';

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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        title TEXT,
        content TEXT NOT NULL,
        mood_emoji TEXT NOT NULL,
        image_path TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_diaries_date ON diaries(date)');
    await db.execute('''
      CREATE TABLE bottles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        mood_emoji TEXT NOT NULL,
        likes_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    // v4 tables for fresh installs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bottle_id INTEGER NOT NULL,
        user_device_id TEXT NOT NULL,
        UNIQUE(bottle_id, user_device_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT NOT NULL,
        mood_emoji TEXT,
        image_path TEXT,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE diaries ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE diaries ADD COLUMN title TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bottles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content TEXT NOT NULL,
          mood_emoji TEXT NOT NULL,
          likes_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // LGS-38: likes table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS likes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bottle_id INTEGER NOT NULL,
          user_device_id TEXT NOT NULL,
          UNIQUE(bottle_id, user_device_id)
        )
      ''');
      // LGS-39: drafts table (single-draft mode)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS drafts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          content TEXT NOT NULL,
          mood_emoji TEXT,
          image_path TEXT,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }

  // --- Diary CRUD ---

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

  Future<DiaryEntry?> getById(int id) async {
    final db = await database;
    final maps = await db.query(
      'diaries',
      where: 'id = ?',
      whereArgs: [id],
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

  // --- Local Bottle CRUD ---

  Future<int> insertBottle(Bottle bottle) async {
    final db = await database;
    return await db.insert('bottles', {
      'content': bottle.content,
      'mood_emoji': bottle.moodEmoji,
      'likes_count': bottle.likesCount,
      'created_at': bottle.createdAt,
    });
  }

  Future<int> getBottleCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM bottles');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Bottle?> getRandomBottle() async {
    final db = await database;
    final count = await getBottleCount();
    if (count == 0) return null;
    final random = DateTime.now().millisecondsSinceEpoch % count;
    final maps = await db.query('bottles', limit: 1, offset: random, orderBy: 'id ASC');
    if (maps.isEmpty) return null;
    return Bottle(
      id: maps[0]['id'].toString(),
      content: maps[0]['content'] as String,
      moodEmoji: maps[0]['mood_emoji'] as String,
      likesCount: maps[0]['likes_count'] as int? ?? 0,
      createdAt: maps[0]['created_at'] as String,
    );
  }

  Future<void> likeBottle(String bottleId) async {
    final db = await database;
    final id = int.tryParse(bottleId);
    if (id == null) return;
    await db.rawUpdate(
      'UPDATE bottles SET likes_count = likes_count + 1 WHERE id = ?',
      [id],
    );
  }

  // --- Likes (LGS-38) ---

  Future<bool> isLiked(int bottleId, String deviceId) async {
    final db = await database;
    final result = await db.query(
      'likes',
      where: 'bottle_id = ? AND user_device_id = ?',
      whereArgs: [bottleId, deviceId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<bool> toggleLike(int bottleId, String deviceId) async {
    final db = await database;
    final existing = await db.query(
      'likes',
      where: 'bottle_id = ? AND user_device_id = ?',
      whereArgs: [bottleId, deviceId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      // Unlike
      await db.delete(
        'likes',
        where: 'bottle_id = ? AND user_device_id = ?',
        whereArgs: [bottleId, deviceId],
      );
      await db.rawUpdate(
        'UPDATE bottles SET likes_count = MAX(0, likes_count - 1) WHERE id = ?',
        [bottleId],
      );
      return false;
    } else {
      // Like
      await db.insert('likes', {
        'bottle_id': bottleId,
        'user_device_id': deviceId,
      });
      await db.rawUpdate(
        'UPDATE bottles SET likes_count = likes_count + 1 WHERE id = ?',
        [bottleId],
      );
      return true;
    }
  }

  // --- Drafts (LGS-39) ---

  Future<void> saveDraft(DiaryEntry entry) async {
    final db = await database;
    await db.delete('drafts'); // single-draft mode
    await db.insert('drafts', {
      'title': entry.title,
      'content': entry.content,
      'mood_emoji': entry.moodEmoji,
      'image_path': entry.imagePath,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<DiaryEntry?> loadDraft() async {
    final db = await database;
    final maps = await db.query('drafts', limit: 1);
    if (maps.isEmpty) return null;
    final map = maps.first;
    return DiaryEntry(
      date: DateTime.now().toIso8601String().substring(0, 10),
      title: map['title'] as String?,
      content: map['content'] as String,
      moodEmoji: (map['mood_emoji'] as String?) ?? '😊',
      imagePath: map['image_path'] as String?,
    );
  }

  Future<void> clearDrafts() async {
    final db = await database;
    await db.delete('drafts');
  }
}

