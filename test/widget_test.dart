import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:guardian_angel/screens/home_screen.dart';

void main() {
  testWidgets('Home screen shows emergency protocols', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(onThemeModeChanged: (_) {}, onLocaleChanged: (_) {}),
      ),
    );

    // The header shows the branded logo image (labelled "Guardian Angel"),
    // not a text widget, so assert on the section title and emergency cards.
    expect(find.text('Select Emergency Type'), findsOneWidget);
    expect(find.text('Nearby Medical Help'), findsOneWidget);
    expect(find.text('Choking'), findsOneWidget);
    expect(find.text('Choking (Infant)'), findsOneWidget);

    // The search bar exposes a voice-search (dictation) button.
    expect(find.byTooltip('Search by voice'), findsOneWidget);
  });
}
