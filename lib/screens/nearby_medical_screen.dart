import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/medical_place_category.dart';
import '../services/location_service.dart';
import '../services/medical_map_link_service.dart';

typedef LocationLoader = Future<Position?> Function();
typedef UrlOpener = Future<bool> Function(Uri uri);

class NearbyMedicalScreen extends StatefulWidget {
  const NearbyMedicalScreen({super.key, this.locationLoader, this.urlOpener});

  final LocationLoader? locationLoader;
  final UrlOpener? urlOpener;

  @override
  State<NearbyMedicalScreen> createState() => _NearbyMedicalScreenState();
}

class _NearbyMedicalScreenState extends State<NearbyMedicalScreen> {
  Position? _position;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLocation());
  }

  Future<void> _refreshLocation() async {
    if (!mounted) return;
    setState(() => _loadingLocation = true);

    Position? position;
    try {
      position =
          await (widget.locationLoader ?? LocationService.getCurrentLocation)();
    } catch (_) {
      position = null;
    }

    if (!mounted) return;
    setState(() {
      _position = position;
      _loadingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          l10n.nearbyMedicalTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SafetyBanner(l10n: l10n),
              const SizedBox(height: 18),
              Text(
                l10n.nearbyMedicalSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _LocationStatus(
                loading: _loadingLocation,
                hasLocation: _position != null,
                onRefresh: _refreshLocation,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: MedicalPlaceCategory.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = MedicalPlaceCategory.values[index];
                    return _MedicalSearchCard(
                      category: category,
                      position: _position,
                      onOpen: _openUri,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUri(Uri uri) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final opener =
          widget.urlOpener ??
          (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
      final launched = await opener(uri);
      if (!launched) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.nearbyMedicalNavigationFailed)),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.nearbyMedicalNavigationFailed)),
      );
    }
  }
}

class _LocationStatus extends StatelessWidget {
  const _LocationStatus({
    required this.loading,
    required this.hasLocation,
    required this.onRefresh,
  });

  final bool loading;
  final bool hasLocation;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final text = loading
        ? l10n.nearbyMedicalCheckingLocation
        : hasLocation
        ? l10n.nearbyMedicalUsingLocation
        : l10n.nearbyMedicalLocationFallback;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          loading
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              : Icon(
                  hasLocation
                      ? Icons.my_location
                      : Icons.location_searching_outlined,
                  color: hasLocation ? cs.tertiary : cs.outline,
                  size: 22,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.nearbyMedicalRefreshLocation,
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _MedicalSearchCard extends StatelessWidget {
  const _MedicalSearchCard({
    required this.category,
    required this.position,
    required this.onOpen,
  });

  final MedicalPlaceCategory category;
  final Position? position;
  final ValueChanged<Uri> onOpen;

  // Brand colors so each button matches its map app's logo.
  static const Color _googleMapsBlue = Color(0xFF1A73E8);
  static const Color _wazeBlue = Color(0xFF0DA9D6);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _categoryColor(category);
    final languageCode = Localizations.localeOf(context).languageCode;
    final latitude = position?.latitude;
    final longitude = position?.longitude;

    final googleMapsUri = MedicalMapLinkService.googleMapsSearchUri(
      category: category,
      languageCode: languageCode,
      latitude: latitude,
      longitude: longitude,
    );
    final wazeUri = MedicalMapLinkService.wazeSearchUri(
      category: category,
      languageCode: languageCode,
      latitude: latitude,
      longitude: longitude,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Image.asset(
                  _categoryIconAsset(category),
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryLabel(l10n, category),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _categoryDescription(l10n, category),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => onOpen(googleMapsUri),
                style: FilledButton.styleFrom(
                  backgroundColor: _googleMapsBlue,
                  foregroundColor: Colors.white,
                ),
                icon: SvgPicture.asset(
                  'assets/branding/google_maps.svg',
                  width: 18,
                  height: 18,
                ),
                label: Text(l10n.nearbyMedicalGoogleMaps),
              ),
              FilledButton.icon(
                onPressed: () => onOpen(wazeUri),
                style: FilledButton.styleFrom(
                  backgroundColor: _wazeBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const FaIcon(FontAwesomeIcons.waze, size: 18),
                label: Text(l10n.nearbyMedicalWaze),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, MedicalPlaceCategory category) {
    return switch (category) {
      MedicalPlaceCategory.hospitals => l10n.nearbyMedicalHospitals,
      MedicalPlaceCategory.pharmacies => l10n.nearbyMedicalPharmacies,
      MedicalPlaceCategory.clinics => l10n.nearbyMedicalClinics,
    };
  }

  String _categoryDescription(
    AppLocalizations l10n,
    MedicalPlaceCategory category,
  ) {
    return switch (category) {
      MedicalPlaceCategory.hospitals => l10n.nearbyMedicalHospitalsSubtitle,
      MedicalPlaceCategory.pharmacies => l10n.nearbyMedicalPharmaciesSubtitle,
      MedicalPlaceCategory.clinics => l10n.nearbyMedicalClinicsSubtitle,
    };
  }

  String _categoryIconAsset(MedicalPlaceCategory category) {
    return switch (category) {
      MedicalPlaceCategory.hospitals =>
        'assets/icons/medical_help/hospitals.png',
      MedicalPlaceCategory.pharmacies =>
        'assets/icons/medical_help/pharmacies.png',
      MedicalPlaceCategory.clinics => 'assets/icons/medical_help/clinics.png',
    };
  }

  Color _categoryColor(MedicalPlaceCategory category) {
    return switch (category) {
      MedicalPlaceCategory.hospitals => AppColors.cprRed,
      MedicalPlaceCategory.pharmacies => AppColors.tertiary,
      MedicalPlaceCategory.clinics => AppColors.fracturePurple,
    };
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(Icons.emergency_outlined, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.nearbyMedicalEmergencyNotice,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
