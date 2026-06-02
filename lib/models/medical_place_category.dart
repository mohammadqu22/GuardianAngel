enum MedicalPlaceCategory { hospitals, pharmacies, clinics }

extension MedicalPlaceCategorySearch on MedicalPlaceCategory {
  /// The map-search term for this category in the given app language.
  ///
  /// [languageCode] may be a bare code ('he') or a locale ('he-IL'); only the
  /// leading subtag is used. Unknown languages fall back to English so the
  /// search still works everywhere.
  String searchQuery([String languageCode = 'en']) {
    final lang = languageCode.split(RegExp('[-_]')).first.toLowerCase();
    switch (this) {
      case MedicalPlaceCategory.hospitals:
        return switch (lang) {
          'he' => 'בית חולים',
          'ar' => 'مستشفى',
          _ => 'hospital',
        };
      case MedicalPlaceCategory.pharmacies:
        return switch (lang) {
          'he' => 'בית מרקחת',
          'ar' => 'صيدلية',
          _ => 'pharmacy',
        };
      case MedicalPlaceCategory.clinics:
        return switch (lang) {
          'he' => 'מרפאה',
          'ar' => 'عيادة',
          _ => 'medical clinic',
        };
    }
  }
}
