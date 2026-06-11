import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_angel/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Recreates the schema a v4 install left on devices (Learning_Progress
/// without the attempt-tracking columns) and verifies DatabaseService
/// upgrades it in place without losing recorded progress.
void main() {
  late String dbPath;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbPath = p.join(await getDatabasesPath(), 'guardian_angel.db');
    await databaseFactory.deleteDatabase(dbPath);

    final v4 = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE User_Settings (
              user_id INTEGER PRIMARY KEY AUTOINCREMENT,
              language_pref TEXT DEFAULT 'en',
              is_first_run INTEGER DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE Emergency_Contact (
              contact_id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              name TEXT NOT NULL,
              phone_number TEXT NOT NULL
            )
          ''');
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
              ended_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE Learning_Progress (
              emergency_type TEXT PRIMARY KEY,
              is_completed INTEGER NOT NULL DEFAULT 0,
              best_score INTEGER,
              quiz_total INTEGER,
              completed_at TEXT
            )
          ''');
        },
      ),
    );
    await v4.insert('Learning_Progress', {
      'emergency_type': 'cpr',
      'is_completed': 1,
      'best_score': 4,
      'quiz_total': 5,
      'completed_at': '2026-06-10T12:00:00.000',
    });
    await v4.close();
  });

  test('v4 database upgrades to the current version keeping progress', () async {
    // First DatabaseService access opens the v4 file and runs the migration.
    final progress = await DatabaseService.getAllLearningProgress();
    final row = progress['cpr']!;
    expect(row['best_score'], 4);
    expect(row['attempts'], 0, reason: 'migrated rows start at 0 attempts');
    expect(row['last_score'], isNull);
    expect(row['partial_answered'], isNull,
        reason: 'v6 partial-progress columns must exist after migration');
    expect(row['partial_selections_json'], isNull,
        reason: 'v7 resume column must exist after migration');

    final attempt = await DatabaseService.recordLearningCompletion(
      'cpr',
      score: 2,
      total: 8,
    );
    expect(attempt, 1);

    final updated = await DatabaseService.getAllLearningProgress();
    expect(updated['cpr']!['best_score'], 4,
        reason: 'pre-migration best score must survive');
    expect(updated['cpr']!['last_score'], 2);
  });
}
