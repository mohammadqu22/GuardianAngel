import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_angel/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Each test file gets its own databases directory: flutter test runs
    // files in parallel, and sharing the default path lets one file's
    // deleteDatabase race another's open connection.
    await databaseFactory.setDatabasesPath(
      Directory.systemTemp.createTempSync('ga_learning_progress_').path,
    );
    // Start from a clean database file so this run is isolated.
    final path = p.join(await getDatabasesPath(), 'guardian_angel.db');
    await databaseFactory.deleteDatabase(path);
  });

  test('learning progress starts empty', () async {
    final progress = await DatabaseService.getAllLearningProgress();
    expect(progress, isEmpty);
  });

  test('recording a completion stores score and completion flag', () async {
    final attempt = await DatabaseService.recordLearningCompletion(
      'cpr',
      score: 3,
      total: 5,
    );
    expect(attempt, 1);

    final progress = await DatabaseService.getAllLearningProgress();
    expect(progress.keys, contains('cpr'));
    final row = progress['cpr']!;
    expect(row['is_completed'], 1);
    expect(row['best_score'], 3);
    expect(row['last_score'], 3);
    expect(row['quiz_total'], 5);
    expect(row['attempts'], 1);
    expect(row['completed_at'], isNotNull);
  });

  test('best score is kept across runs while attempts accumulate', () async {
    final attempt = await DatabaseService.recordLearningCompletion(
      'cpr',
      score: 2,
      total: 5,
    );
    expect(attempt, 2);

    var progress = await DatabaseService.getAllLearningProgress();
    expect(progress['cpr']!['best_score'], 3,
        reason: 'a worse retake must not lower the best score');
    expect(progress['cpr']!['last_score'], 2);
    expect(progress['cpr']!['attempts'], 2);

    await DatabaseService.recordLearningCompletion('cpr', score: 5, total: 5);
    progress = await DatabaseService.getAllLearningProgress();
    expect(progress['cpr']!['best_score'], 5);
    expect(progress['cpr']!['attempts'], 3);
  });

  test('abandoned quiz runs record partial progress', () async {
    await DatabaseService.recordQuizPartialProgress(
      'choking',
      answered: 3,
      correct: 2,
      total: 7,
      selections: [0, 2, 1],
    );

    final progress = await DatabaseService.getAllLearningProgress();
    final row = progress['choking']!;
    expect(row['is_completed'], 0,
        reason: 'a partial run must not count as completed');
    expect(row['partial_answered'], 3);
    expect(row['partial_correct'], 2);
    expect(row['partial_total'], 7);
    expect(row['partial_selections_json'], '[0,2,1]',
        reason: 'per-question picks are stored so the quiz can resume');
  });

  test('finishing the quiz clears partial progress', () async {
    await DatabaseService.recordLearningCompletion(
      'choking',
      score: 5,
      total: 7,
    );

    final progress = await DatabaseService.getAllLearningProgress();
    final row = progress['choking']!;
    expect(row['is_completed'], 1);
    expect(row['best_score'], 5);
    expect(row['partial_answered'], isNull);
    expect(row['partial_correct'], isNull);
    expect(row['partial_total'], isNull);
    expect(row['partial_selections_json'], isNull);
  });

  test('partial progress after completion keeps completion data', () async {
    await DatabaseService.recordQuizPartialProgress(
      'choking',
      answered: 1,
      correct: 1,
      total: 7,
      selections: [3],
    );

    final progress = await DatabaseService.getAllLearningProgress();
    final row = progress['choking']!;
    expect(row['is_completed'], 1,
        reason: 'an abandoned retake must not erase the completed badge');
    expect(row['best_score'], 5);
    expect(row['attempts'], 1);
    expect(row['partial_answered'], 1);
  });

  test('learning completions never touch the incident log', () async {
    await DatabaseService.recordLearningCompletion(
      'burns',
      score: 4,
      total: 5,
    );
    final incidents = await DatabaseService.getIncidentLog();
    expect(incidents, isEmpty);
  });
}
