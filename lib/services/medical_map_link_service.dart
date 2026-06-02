import '../models/medical_place_category.dart';

class MedicalMapLinkService {
  const MedicalMapLinkService._();

  static Uri googleMapsSearchUri({
    required MedicalPlaceCategory category,
    String languageCode = 'en',
    double? latitude,
    double? longitude,
  }) {
    final query = _query(
      category,
      languageCode: languageCode,
      latitude: latitude,
      longitude: longitude,
    );
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
  }

  static Uri wazeSearchUri({
    required MedicalPlaceCategory category,
    String languageCode = 'en',
    double? latitude,
    double? longitude,
  }) {
    final coordinates = _coordinates(latitude, longitude);
    return Uri.https('waze.com', '/ul', {
      'q': category.searchQuery(languageCode),
      if (coordinates != null) 'll': coordinates,
    });
  }

  static String _query(
    MedicalPlaceCategory category, {
    required String languageCode,
    double? latitude,
    double? longitude,
  }) {
    final term = category.searchQuery(languageCode);
    final coordinates = _coordinates(latitude, longitude);
    final lang = languageCode.split(RegExp('[-_]')).first.toLowerCase();
    if (coordinates == null) {
      return switch (lang) {
        'he' => '$term בקרבת מקום',
        'ar' => '$term قريب مني',
        _ => 'nearby $term',
      };
    }
    return switch (lang) {
      'he' => '$term ליד $coordinates',
      'ar' => '$term بالقرب من $coordinates',
      _ => '$term near $coordinates',
    };
  }

  static String? _coordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    return '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
  }
}
