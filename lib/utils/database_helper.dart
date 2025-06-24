import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ini_berapa/models/detection_history.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    // --- TAMBAHAN UNTUK DEBUGGING ---
    debugPrint("LOKASI DATABASE: $path"); 
    // --------------------------------

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    
    await db.execute('''
      CREATE TABLE history ( 
        id $idType, 
        label $textType,
        imagePath $textType,
        timestamp $textType
      )
    ''');
  }

  Future<void> insertHistory(DetectionHistory history) async {
    final db = await instance.database;
    await db.insert('history', history.toMap());
  }

  Future<List<DetectionHistory>> getAllHistory() async {
    final db = await instance.database;
    final result = await db.query('history', orderBy: 'timestamp DESC');
    return result.map((json) => DetectionHistory.fromMap(json)).toList();
  }
  
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}