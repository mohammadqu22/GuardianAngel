import 'package:flutter/widgets.dart';

String formatLocalizedDuration(BuildContext context, int seconds) {
  String unit(
    int value,
    String en,
    String arSingular,
    String arPlural,
    String heSingular,
    String hePlural,
  ) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'ar') return value == 1 ? arSingular : arPlural;
    if (code == 'he') return value == 1 ? heSingular : hePlural;
    return en;
  }

  if (seconds < 60) {
    return '$seconds ${unit(seconds, 's', 'ثانية', 'ثواني', 'שנייה', 'שניות')}';
  }

  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  if (minutes < 60) {
    final minuteText =
        '$minutes ${unit(minutes, 'm', 'دقيقة', 'دقائق', 'דקה', 'דקות')}';
    return remainingSeconds == 0
        ? minuteText
        : '$minuteText ${formatLocalizedDuration(context, remainingSeconds)}';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  final hourText = '$hours ${unit(hours, 'h', 'ساعة', 'ساعات', 'שעה', 'שעות')}';
  return remainingMinutes == 0
      ? hourText
      : '$hourText ${formatLocalizedDuration(context, remainingMinutes * 60)}';
}
