import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import 'package:guardian_angel/screens/nearby_medical_screen.dart';

void main() {
  testWidgets('Nearby Medical Help opens generic map searches without location', (
    tester,
  ) async {
    final openedUris = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NearbyMedicalScreen(
          locationLoader: () async => null,
          urlOpener: (uri) async {
            openedUris.add(uri);
            return true;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hospitals'), findsOneWidget);
    expect(find.text('Pharmacies'), findsOneWidget);
    expect(
      find.text(
        'Location is unavailable. Searches will still open without your coordinates.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Google Maps').first);
    await tester.pumpAndSettle();

    expect(openedUris, hasLength(1));
    expect(openedUris.single.host, 'www.google.com');
    expect(openedUris.single.queryParameters['query'], 'nearby hospital');

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(find.text('Clinics'), findsOneWidget);
  });
}
