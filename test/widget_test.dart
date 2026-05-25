import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:guardian_angel/screens/home_screen.dart';

void main() {
  testWidgets('Home screen shows emergency protocols', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(
          onThemeModeChanged: (_) {},
          onLocaleChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Guardian Angel'), findsOneWidget);
    expect(find.text('Select Emergency Type'), findsOneWidget);
    expect(find.text('Choking'), findsOneWidget);
    expect(find.text('Choking (Infant)'), findsOneWidget);
  });
}
