import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  // Get or create the database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'guardian_angel.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // User Settings table
    await db.execute('''
      CREATE TABLE User_Settings (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        language_pref TEXT DEFAULT 'en',
        is_first_run INTEGER DEFAULT 1
      )
    ''');

    // Emergency Contact table
    await db.execute('''
      CREATE TABLE Emergency_Contact (
        contact_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES User_Settings(user_id)
      )
    ''');

    // Incident Log table
    await db.execute('''
      CREATE TABLE Incident_Log (
        log_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        timestamp TEXT NOT NULL,
        emergency_type TEXT NOT NULL,
        completed_steps INTEGER DEFAULT 0,
        total_steps INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        elapsed_seconds INTEGER DEFAULT 0,
        step_durations_json TEXT DEFAULT '[]',
        ended_at TEXT,
        FOREIGN KEY (user_id) REFERENCES User_Settings(user_id)
      )
    ''');

    // Learning Progress table (Learning Mode practice results)
    await db.execute(_createLearningProgressSql);

    // Insert default user settings on first run
    await db.insert('User_Settings', {
      'language_pref': 'en',
      'is_first_run': 1,
    });
  }

  static const String _createLearningProgressSql = '''
      CREATE TABLE Learning_Progress (
        emergency_type TEXT PRIMARY KEY,
        is_completed INTEGER NOT NULL DEFAULT 0,
        best_score INTEGER,
        quiz_total INTEGER,
        completed_at TEXT,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_score INTEGER,
        partial_answered INTEGER,
        partial_correct INTEGER,
        partial_total INTEGER,
        partial_selections_json TEXT
      )
    ''';

  static Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE Incident_Log ADD COLUMN completed_steps INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE Incident_Log ADD COLUMN total_steps INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE Incident_Log ADD COLUMN is_completed INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE Incident_Log ADD COLUMN elapsed_seconds INTEGER DEFAULT 0',
      );
      await db.execute(
        "ALTER TABLE Incident_Log ADD COLUMN step_durations_json TEXT DEFAULT '[]'",
      );
      await db.execute('ALTER TABLE Incident_Log ADD COLUMN ended_at TEXT');
    }
    if (oldVersion < 4) {
      await db.execute(_createLearningProgressSql);
    }
    // Learning_Progress upgrades only apply to versions that already had the
    // table (v4+); older versions got the full current schema above.
    if (oldVersion == 4) {
      // v5 added attempt tracking.
      await db.execute(
        'ALTER TABLE Learning_Progress ADD COLUMN attempts INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE Learning_Progress ADD COLUMN last_score INTEGER',
      );
    }
    if (oldVersion == 4 || oldVersion == 5) {
      // v6 tracks abandoned quizzes (partial progress).
      await db.execute(
        'ALTER TABLE Learning_Progress ADD COLUMN partial_answered INTEGER',
      );
      await db.execute(
        'ALTER TABLE Learning_Progress ADD COLUMN partial_correct INTEGER',
      );
      await db.execute(
        'ALTER TABLE Learning_Progress ADD COLUMN partial_total INTEGER',
      );
    }
    if (oldVersion >= 4 && oldVersion < 7) {
      // v7 stores the per-question picks so an abandoned quiz can resume.
      await db.execute(
        'ALTER TABLE Learning_Progress ADD COLUMN partial_selections_json TEXT',
      );
    }
  }

  // ─── User Settings ───────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserSettings() async {
    final db = await database;
    final results = await db.query('User_Settings', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  static Future<void> updateLanguage(String langCode) async {
    final db = await database;
    await db.update(
      'User_Settings',
      {'language_pref': langCode},
      where: 'user_id = ?',
      whereArgs: [1],
    );
  }

  // ─── Emergency Contact ───────────────────────────────────

  static Future<void> saveEmergencyContact(String name, String phone) async {
    final db = await database;
    // Delete old contact first (only one contact supported for now)
    await db.delete('Emergency_Contact');
    await db.insert('Emergency_Contact', {
      'user_id': 1,
      'name': name,
      'phone_number': phone,
    });
  }

  static Future<Map<String, dynamic>?> getEmergencyContact() async {
    final db = await database;
    final results = await db.query('Emergency_Contact', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  static Future<void> deleteEmergencyContact() async {
    final db = await database;
    await db.delete('Emergency_Contact');
  }

  // ─── Incident Log ─────────────────────────────────────────

  static Future<int> logIncident(String emergencyType) async {
    final db = await database;
    return await db.insert('Incident_Log', {
      'user_id': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'emergency_type': emergencyType,
    });
  }

  static Future<void> updateIncidentProgress({
    required int logId,
    required int completedSteps,
    required int totalSteps,
    required bool isCompleted,
    int? elapsedSeconds,
    List<int>? stepDurations,
    bool markEnded = false,
  }) async {
    final db = await database;
    final values = <String, Object?>{
      'completed_steps': completedSteps,
      'total_steps': totalSteps,
      'is_completed': isCompleted ? 1 : 0,
    };
    if (elapsedSeconds != null) {
      values['elapsed_seconds'] = elapsedSeconds;
    }
    if (stepDurations != null) {
      values['step_durations_json'] = jsonEncode(stepDurations);
    }
    if (markEnded) {
      values['ended_at'] = DateTime.now().toIso8601String();
    }

    await db.update(
      'Incident_Log',
      values,
      where: 'log_id = ?',
      whereArgs: [logId],
    );
  }

  static Future<List<Map<String, dynamic>>> getIncidentLog() async {
    final db = await database;
    return await db.query('Incident_Log', orderBy: 'timestamp DESC');
  }

  static Future<void> clearIncidentLog() async {
    final db = await database;
    await db.delete('Incident_Log');
  }

  static Future<void> deleteIncidentLog(int logId) async {
    final db = await database;
    await db.delete('Incident_Log', where: 'log_id = ?', whereArgs: [logId]);
  }

  static Future<void> deleteIncidentLogs(List<int> logIds) async {
    if (logIds.isEmpty) return;

    final db = await database;
    final placeholders = List.filled(logIds.length, '?').join(', ');
    await db.delete(
      'Incident_Log',
      where: 'log_id IN ($placeholders)',
      whereArgs: logIds,
    );
  }

  // ─── Learning Progress ────────────────────────────────────

  /// Returns learning progress keyed by emergency id.
  static Future<Map<String, Map<String, dynamic>>>
  getAllLearningProgress() async {
    final db = await database;
    final rows = await db.query('Learning_Progress');
    return {for (final row in rows) row['emergency_type'] as String: row};
  }

  /// Marks a lesson as completed, keeps the best quiz score across runs, and
  /// returns the attempt number this completion represents (1 for the first).
  static Future<int> recordLearningCompletion(
    String emergencyType, {
    required int score,
    required int total,
  }) async {
    final db = await database;
    final existing = await db.query(
      'Learning_Progress',
      where: 'emergency_type = ?',
      whereArgs: [emergencyType],
      limit: 1,
    );
    final previous = existing.isNotEmpty ? existing.first : null;
    final previousBest = previous?['best_score'] as int?;
    final best = previousBest == null || score > previousBest
        ? score
        : previousBest;
    final attempts = ((previous?['attempts'] as int?) ?? 0) + 1;
    await db.insert('Learning_Progress', {
      'emergency_type': emergencyType,
      'is_completed': 1,
      'best_score': best,
      'quiz_total': total,
      'completed_at': DateTime.now().toIso8601String(),
      'attempts': attempts,
      'last_score': score,
      // A finished quiz supersedes any abandoned-run progress.
      'partial_answered': null,
      'partial_correct': null,
      'partial_total': null,
      'partial_selections_json': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return attempts;
  }

  /// Saves how far an unfinished quiz run got, without touching completion
  /// data, so an abandoned quiz still shows progress on the learning card and
  /// can be resumed exactly where it stopped. [selections] holds the chosen
  /// option index per answered question, in question order.
  static Future<void> recordQuizPartialProgress(
    String emergencyType, {
    required int answered,
    required int correct,
    required int total,
    required List<int> selections,
  }) async {
    final db = await database;
    final existing = await db.query(
      'Learning_Progress',
      where: 'emergency_type = ?',
      whereArgs: [emergencyType],
      limit: 1,
    );
    final merged = <String, Object?>{
      if (existing.isNotEmpty) ...existing.first,
      'emergency_type': emergencyType,
      'partial_answered': answered,
      'partial_correct': correct,
      'partial_total': total,
      'partial_selections_json': jsonEncode(selections),
    };
    await db.insert(
      'Learning_Progress',
      merged,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
