import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'english_words.db');

    // 如果数据库文件不存在，就从 assets 复制
    if (!File(path).existsSync()) {
      ByteData data = await rootBundle.load("assets/english_words.db");
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
    }

    // 打开数据库
    return await openDatabase(path);
  }

  // 获取单词总数
  Future<int> getTotalWords() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM wordlists');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 获取已学单词数
  Future<int> getRecitedWords() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM recite_word');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 获取已学单词数
  Future<int> getRecitedWordsByType(String reciteType) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM recite_word WHERE recite_type = ?',
      [reciteType]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 获取今天学习的单词数量
  Future<int> getRecitedWordsByDay(int day) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM recite_word WHERE day = ?', [day]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 添加已学单词，如果word存在则更新reciteType
  Future<void> addRecitedWord(String word, String reciteType, int day) async {
    final db = await database;
    final result = await db.rawQuery('SELECT * FROM recite_word WHERE word = ?', [word]);
    if (result.isNotEmpty) {
      await db.update('recite_word', {
        'recite_type': reciteType,
      }, where: 'word = ?', whereArgs: [word]);
    } else {
      await db.insert('recite_word', {
        'word': word,
        'recite_type': reciteType,
        'day': day,
        'create_time': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // 更新已学单词
  Future<void> updateReciteWord(String word, String reciteType) async {
    final db = await database;
    await db.update('recite_word', {
      'recite_type': reciteType,
    }, where: 'word = ?', whereArgs: [word]);
  }

  // 添加复习单词
  Future<void> addReviewWord(String word) async {
    final db = await database;
    final result = await db.rawQuery('SELECT * FROM review_word WHERE word = ?', [word]);
    if (result.isEmpty) {
      await db.insert('review_word', {
        'word': word,
        'create_time': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // 添加复习单词
  Future<void> addReviewWords(int day) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT * FROM recite_word
      WHERE recite_type = 'recite' AND (day = ? OR day = ? OR day = ? OR day = ?)
    ''', [day - 1, day - 3, day - 6, day - 14]);
    for (var word in result) {
      await addReviewWord(word['word'] as String);
    }
  }

  // 添加复习单词
  Future<void> addTodayReviewWords(int day) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT * FROM recite_word
      WHERE recite_type = 'recite' AND day = ?
    ''', [day]);
    for (var word in result) {
      await addReviewWord(word['word'] as String);
    }
  }

  // 删除复习单词
  Future<void> deleteReviewWord(String word) async {
    final db = await database;
    await db.delete('review_word', where: 'word = ?', whereArgs: [word]);
  }

  // 获取第一个未学单词
  Future<Map<String, dynamic>?> getFirstUnrecitedWord() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT * FROM wordlists 
      WHERE word NOT IN (SELECT word FROM recite_word)
      ORDER BY id ASC
      LIMIT 1
    ''');
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // 获取所有今日复习单词
  Future<List<Map<String, dynamic>>> getTodayReviewWords() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT * FROM wordlists 
      WHERE word IN (SELECT word FROM review_word)
      ORDER BY id ASC
      ''');
    return result;
  }

  // 获取配置
  Future<String> getConfig(String configName) async {
    final db = await database;
    final result = await db.rawQuery('SELECT * FROM config WHERE config_name = ?', [configName]);
    if (result.isNotEmpty) {
      return result.first['config_value'] as String;
    }
    return '';
  }

  // 设置配置
  Future<void> setConfig(String configName, String configValue) async {
    final db = await database;
    await db.update('config', {'config_value': configValue}, where: 'config_name = ?', whereArgs: [configName]);
  }

  // 添加reciteLog
  Future<void> addReciteLog(String word, int recite) async {
    final db = await database;
    await db.insert('recite_log', {
      'word': word,
      'recite': recite,
      'create_time': DateTime.now().millisecondsSinceEpoch,
    });
  }

}
