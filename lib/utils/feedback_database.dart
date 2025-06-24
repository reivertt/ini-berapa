import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FeedbackDatabase {
  static Database? _database;
  static const String _tableName = 'feedback';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'feedback.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            detected_value TEXT NOT NULL,
            is_correct INTEGER NOT NULL,
            actual_value TEXT,
            image_path TEXT,
            confidence_score REAL
          )
        ''');
      },
    );
  }

  static Future<int> insertFeedback({
    required String detectedValue,
    required bool isCorrect,
    String? actualValue,
    String? imagePath,
    double? confidenceScore,
  }) async {
    final db = await database;
    
    return await db.insert(_tableName, {
      'timestamp': DateTime.now().toIso8601String(),
      'detected_value': detectedValue,
      'is_correct': isCorrect ? 1 : 0,
      'actual_value': actualValue,
      'image_path': imagePath,
      'confidence_score': confidenceScore,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final db = await database;
    return await db.query(_tableName, orderBy: 'timestamp DESC');
  }

  static Future<Map<String, dynamic>> getFeedbackStats() async {
    final db = await database;
    
    // Get total feedback count
    final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM $_tableName');
    final total = totalResult.first['total'] as int;
    
    // Get correct feedback count
    final correctResult = await db.rawQuery('SELECT COUNT(*) as correct FROM $_tableName WHERE is_correct = 1');
    final correct = correctResult.first['correct'] as int;
    
    // Get accuracy percentage
    final accuracy = total > 0 ? (correct / total * 100) : 0.0;
    
    // Get most common incorrect detections
    final incorrectDetections = await db.rawQuery('''
      SELECT detected_value, COUNT(*) as count 
      FROM $_tableName 
      WHERE is_correct = 0 
      GROUP BY detected_value 
      ORDER BY count DESC 
      LIMIT 5
    ''');
    
    return {
      'total_feedback': total,
      'correct_feedback': correct,
      'incorrect_feedback': total - correct,
      'accuracy_percentage': accuracy,
      'common_errors': incorrectDetections,
    };
  }

  static Future<void> clearAllFeedback() async {
    final db = await database;
    await db.delete(_tableName);
  }

  static Future<void> deleteFeedback(int id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
