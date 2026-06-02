import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_angel/models/medical_place_category.dart';
import 'package:guardian_angel/services/medical_map_link_service.dart';

void main() {
  test('Google Maps search uses coordinates when location is available', () {
    final uri = MedicalMapLinkService.googleMapsSearchUri(
      category: MedicalPlaceCategory.hospitals,
      latitude: 31.771959,
      longitude: 35.217018,
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['query'], 'hospital near 31.771959,35.217018');
  });

  test('Google Maps search falls back to a generic nearby query', () {
    final uri = MedicalMapLinkService.googleMapsSearchUri(
      category: MedicalPlaceCategory.pharmacies,
    );

    expect(uri.queryParameters['query'], 'nearby pharmacy');
  });

  test('Search terms and connectors are localized per app language', () {
    final he = MedicalMapLinkService.googleMapsSearchUri(
      category: MedicalPlaceCategory.hospitals,
      languageCode: 'he-IL',
      latitude: 31.771959,
      longitude: 35.217018,
    );
    expect(he.queryParameters['query'], 'בית חולים ליד 31.771959,35.217018');

    final ar = MedicalMapLinkService.googleMapsSearchUri(
      category: MedicalPlaceCategory.pharmacies,
      languageCode: 'ar',
    );
    expect(ar.queryParameters['query'], 'صيدلية قريب مني');

    final arWaze = MedicalMapLinkService.wazeSearchUri(
      category: MedicalPlaceCategory.clinics,
      languageCode: 'ar',
    );
    expect(arWaze.queryParameters['q'], 'عيادة');
  });

  test('Waze search adds coordinates only when they are available', () {
    final uriWithLocation = MedicalMapLinkService.wazeSearchUri(
      category: MedicalPlaceCategory.clinics,
      latitude: 31.771959,
      longitude: 35.217018,
    );
    final uriWithoutLocation = MedicalMapLinkService.wazeSearchUri(
      category: MedicalPlaceCategory.clinics,
    );

    expect(uriWithLocation.host, 'waze.com');
    expect(uriWithLocation.queryParameters['q'], 'medical clinic');
    expect(uriWithLocation.queryParameters['ll'], '31.771959,35.217018');
    expect(uriWithoutLocation.queryParameters['q'], 'medical clinic');
    expect(uriWithoutLocation.queryParameters.containsKey('ll'), isFalse);
  });
}
