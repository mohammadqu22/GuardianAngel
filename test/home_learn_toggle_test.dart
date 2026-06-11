import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:guardian_angel/screens/home_screen.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(onThemeModeChanged: (_) {}, onLocaleChanged: (_) {}),
      ),
    );
  }

  testWidgets('Home defaults to Emergency mode with the mode switch shown', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Select Emergency Type'), findsOneWidget);
    expect(find.text('Nearby Medical Help'), findsOneWidget);
    expect(find.text('CALL 101'), findsOneWidget);
  });

  testWidgets('Learn mode shows learning cards with progress status', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.text('Learn'));
    await tester.pump();

    expect(find.text('Practice First Aid'), findsOneWidget);
    // No SQLite plugin in widget tests, so all protocols read as not started.
    expect(find.text('Not started'), findsWidgets);
    expect(find.text('0 of 8 lessons completed'), findsOneWidget);
    // Emergency-only entry points are hidden while practicing.
    expect(find.text('Nearby Medical Help'), findsNothing);
    expect(find.text('Select Emergency Type'), findsNothing);
    expect(find.text('CALL 101'), findsNothing);
  });

  testWidgets('Focusing search makes other controls inert until tap-away', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    // First tap on another control only dismisses focus — mode must not flip.
    await tester.tap(find.text('Learn'));
    await tester.pump();
    expect(find.text('Select Emergency Type'), findsOneWidget);
    expect(find.text('Practice First Aid'), findsNothing);

    // Focus is gone now, so the same tap works normally.
    await tester.tap(find.text('Learn'));
    await tester.pump();
    expect(find.text('Practice First Aid'), findsOneWidget);
  });

  testWidgets('Switching back restores the Emergency home', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Learn'));
    await tester.pump();
    await tester.tap(find.text('Emergency'));
    await tester.pump();

    expect(find.text('Select Emergency Type'), findsOneWidget);
    expect(find.text('Nearby Medical Help'), findsOneWidget);
    expect(find.text('Not started'), findsNothing);
  });
}
