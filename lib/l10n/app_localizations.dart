import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Guardian Angel'**
  String get appName;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Response'**
  String get homeSubtitle;

  /// No description provided for @homeSelectEmergency.
  ///
  /// In en, this message translates to:
  /// **'Select Emergency Type'**
  String get homeSelectEmergency;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search emergency...'**
  String get homeSearchHint;

  /// No description provided for @homeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No emergency found'**
  String get homeNoResults;

  /// No description provided for @homeCallBtn.
  ///
  /// In en, this message translates to:
  /// **'CALL 101'**
  String get homeCallBtn;

  /// No description provided for @homeCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open dialer. Please call 101 manually.'**
  String get homeCallFailed;

  /// No description provided for @homeSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsTooltip;

  /// No description provided for @emergencyChoking.
  ///
  /// In en, this message translates to:
  /// **'Choking'**
  String get emergencyChoking;

  /// No description provided for @emergencyChokingInfant.
  ///
  /// In en, this message translates to:
  /// **'Choking (Infant)'**
  String get emergencyChokingInfant;

  /// Cardiopulmonary resuscitation. REVIEW: kept as 'CPR' in English; verify translated form with stakeholders.
  ///
  /// In en, this message translates to:
  /// **'CPR'**
  String get emergencyCPR;

  /// No description provided for @emergencyCPRInfant.
  ///
  /// In en, this message translates to:
  /// **'CPR (Infant)'**
  String get emergencyCPRInfant;

  /// No description provided for @emergencyBurns.
  ///
  /// In en, this message translates to:
  /// **'Burns'**
  String get emergencyBurns;

  /// No description provided for @emergencyBleeding.
  ///
  /// In en, this message translates to:
  /// **'Bleeding'**
  String get emergencyBleeding;

  /// No description provided for @emergencyFractures.
  ///
  /// In en, this message translates to:
  /// **'Fractures'**
  String get emergencyFractures;

  /// No description provided for @emergencySeizures.
  ///
  /// In en, this message translates to:
  /// **'Seizures'**
  String get emergencySeizures;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepProgress(int current, int total);

  /// No description provided for @stepNext.
  ///
  /// In en, this message translates to:
  /// **'NEXT STEP'**
  String get stepNext;

  /// No description provided for @stepDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get stepDone;

  /// No description provided for @stepPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get stepPrevious;

  /// No description provided for @stepWarningsBtn.
  ///
  /// In en, this message translates to:
  /// **'View important warnings'**
  String get stepWarningsBtn;

  /// No description provided for @stepWarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT WARNINGS'**
  String get stepWarningsTitle;

  /// No description provided for @stepWarningsGotIt.
  ///
  /// In en, this message translates to:
  /// **'GOT IT'**
  String get stepWarningsGotIt;

  /// No description provided for @stepErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Protocol data is invalid. Please reinstall the app.'**
  String get stepErrorInvalid;

  /// No description provided for @stepErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load protocol. Please restart the app.'**
  String get stepErrorFailed;

  /// No description provided for @stepCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'TREATMENT COMPLETE'**
  String get stepCompleteTitle;

  /// No description provided for @stepCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'All protocol steps have been successfully administered for {emergencyTitle}.'**
  String stepCompleteBody(String emergencyTitle);

  /// No description provided for @stepCompleteVitalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor Patient Vitals'**
  String get stepCompleteVitalsTitle;

  /// No description provided for @stepCompleteVitalsBody.
  ///
  /// In en, this message translates to:
  /// **'Maintain clinical observation. Ensure the patient remains warm and avoid sudden movements while waiting for medical staff arrival.'**
  String get stepCompleteVitalsBody;

  /// No description provided for @stepCompleteTimingTitle.
  ///
  /// In en, this message translates to:
  /// **'Protocol Timing'**
  String get stepCompleteTimingTitle;

  /// No description provided for @stepCompleteTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get stepCompleteTotalTime;

  /// No description provided for @stepCompleteStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get stepCompleteStartedAt;

  /// No description provided for @stepCompleteFinishedAt.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get stepCompleteFinishedAt;

  /// No description provided for @stepCompleteIncidentLogHint.
  ///
  /// In en, this message translates to:
  /// **'You can review this session later in Settings > Incident Log.'**
  String get stepCompleteIncidentLogHint;

  /// No description provided for @stepCompleteDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This app does not replace professional medical care. Seek a doctor if needed.'**
  String get stepCompleteDisclaimer;

  /// No description provided for @stepCompleteBackBtn.
  ///
  /// In en, this message translates to:
  /// **'BACK TO HOME'**
  String get stepCompleteBackBtn;

  /// No description provided for @stepRepeatAudio.
  ///
  /// In en, this message translates to:
  /// **'Repeat audio'**
  String get stepRepeatAudio;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your life-saving assistant.'**
  String get settingsSubtitle;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get settingsTheme;

  /// No description provided for @settingsVoiceGuidance.
  ///
  /// In en, this message translates to:
  /// **'Voice Guidance'**
  String get settingsVoiceGuidance;

  /// No description provided for @settingsTtsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'TTS Audio Instructions'**
  String get settingsTtsSubtitle;

  /// No description provided for @settingsSectionEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get settingsSectionEmergencyContact;

  /// No description provided for @settingsAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get settingsAddContact;

  /// No description provided for @settingsAddContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a trusted person to call in emergencies'**
  String get settingsAddContactSubtitle;

  /// No description provided for @settingsSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location Tools'**
  String get settingsSectionLocation;

  /// No description provided for @settingsShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share My Location'**
  String get settingsShareLocation;

  /// No description provided for @settingsShareLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live updates with emergency services'**
  String get settingsShareLocationSubtitle;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get settingsSectionInfo;

  /// No description provided for @settingsMedicalSources.
  ///
  /// In en, this message translates to:
  /// **'Medical Sources'**
  String get settingsMedicalSources;

  /// No description provided for @settingsMedicalSourcesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View our verified sources'**
  String get settingsMedicalSourcesSubtitle;

  /// No description provided for @settingsIncidentLog.
  ///
  /// In en, this message translates to:
  /// **'Incident Log'**
  String get settingsIncidentLog;

  /// No description provided for @settingsIncidentLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review recently opened emergency protocols'**
  String get settingsIncidentLogSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Guardian Angel'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App information & version'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Disclaimer'**
  String get settingsDisclaimerTitle;

  /// No description provided for @settingsDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'This application is an educational and supportive tool. It does not replace professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions regarding a medical condition. In case of a life-threatening emergency, call your local emergency services immediately.'**
  String get settingsDisclaimerBody;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsClose;

  /// No description provided for @settingsThemeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get settingsThemeDialogTitle;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsContactDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get settingsContactDialogTitle;

  /// No description provided for @settingsContactName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsContactName;

  /// No description provided for @settingsContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get settingsContactPhone;

  /// No description provided for @settingsContactDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsContactDelete;

  /// No description provided for @settingsContactSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get settingsContactSave;

  /// No description provided for @settingsContactValidation.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both fields'**
  String get settingsContactValidation;

  /// No description provided for @settingsContactDeleted.
  ///
  /// In en, this message translates to:
  /// **'Contact deleted'**
  String get settingsContactDeleted;

  /// No description provided for @settingsContactSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved as emergency contact'**
  String settingsContactSaved(String name);

  /// No description provided for @settingsCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open dialer'**
  String get settingsCallFailed;

  /// No description provided for @settingsCallContactTooltip.
  ///
  /// In en, this message translates to:
  /// **'Call contact'**
  String get settingsCallContactTooltip;

  /// No description provided for @settingsEditContactTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get settingsEditContactTooltip;

  /// No description provided for @settingsLocationFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get settingsLocationFetching;

  /// No description provided for @settingsLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get location. Check GPS settings.'**
  String get settingsLocationFailed;

  /// No description provided for @settingsLocationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get settingsLocationDialogTitle;

  /// No description provided for @settingsLocationShareHint.
  ///
  /// In en, this message translates to:
  /// **'Share this link with someone to show your location:'**
  String get settingsLocationShareHint;

  /// No description provided for @settingsLocationCoords.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {coords}'**
  String settingsLocationCoords(String coords);

  /// No description provided for @settingsLocationCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get settingsLocationCopy;

  /// No description provided for @settingsLocationCopied.
  ///
  /// In en, this message translates to:
  /// **'Location link copied! 📋'**
  String get settingsLocationCopied;

  /// No description provided for @incidentLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Log'**
  String get incidentLogTitle;

  /// No description provided for @incidentLogEntry.
  ///
  /// In en, this message translates to:
  /// **'Opened {emergencyTitle} protocol'**
  String incidentLogEntry(String emergencyTitle);

  /// No description provided for @incidentLogProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} steps reached'**
  String incidentLogProgress(int completed, int total);

  /// No description provided for @incidentLogCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed all steps'**
  String get incidentLogCompleted;

  /// No description provided for @incidentLogTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time: {duration}'**
  String incidentLogTotalTime(String duration);

  /// No description provided for @incidentLogStepTimes.
  ///
  /// In en, this message translates to:
  /// **'Step times: {times}'**
  String incidentLogStepTimes(String times);

  /// No description provided for @incidentLogStepTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Step times'**
  String get incidentLogStepTimesTitle;

  /// No description provided for @incidentLogStepTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step}'**
  String incidentLogStepTimeLabel(int step);

  /// No description provided for @incidentLogNoTimingDetails.
  ///
  /// In en, this message translates to:
  /// **'No timing details available'**
  String get incidentLogNoTimingDetails;

  /// No description provided for @incidentLogEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No incidents yet'**
  String get incidentLogEmptyTitle;

  /// No description provided for @incidentLogEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Opened emergency protocols will appear here for quick review.'**
  String get incidentLogEmptyBody;

  /// No description provided for @incidentLogLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load incident log'**
  String get incidentLogLoadFailed;

  /// No description provided for @incidentLogLoadFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Please restart the app and try again.'**
  String get incidentLogLoadFailedBody;

  /// No description provided for @incidentLogClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear incident log?'**
  String get incidentLogClearTitle;

  /// No description provided for @incidentLogClearBody.
  ///
  /// In en, this message translates to:
  /// **'This removes all saved incident history from this device.'**
  String get incidentLogClearBody;

  /// No description provided for @incidentLogClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get incidentLogClearAction;

  /// No description provided for @incidentLogCleared.
  ///
  /// In en, this message translates to:
  /// **'Incident log cleared'**
  String get incidentLogCleared;

  /// No description provided for @incidentLogClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not clear incident log'**
  String get incidentLogClearFailed;

  /// No description provided for @incidentLogDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get incidentLogDeleteAction;

  /// No description provided for @incidentLogDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this incident?'**
  String get incidentLogDeleteTitle;

  /// No description provided for @incidentLogDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This incident will be permanently removed from the log.'**
  String get incidentLogDeleteBody;

  /// No description provided for @incidentLogDeleted.
  ///
  /// In en, this message translates to:
  /// **'Incident deleted'**
  String get incidentLogDeleted;

  /// No description provided for @incidentLogDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete incident'**
  String get incidentLogDeleteFailed;

  /// No description provided for @incidentLogSelectAction.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get incidentLogSelectAction;

  /// No description provided for @incidentLogSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String incidentLogSelectionTitle(int count);

  /// No description provided for @incidentLogDeleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected incidents?'**
  String get incidentLogDeleteSelectedTitle;

  /// No description provided for @incidentLogDeleteSelectedBody.
  ///
  /// In en, this message translates to:
  /// **'The selected incidents will be permanently removed from the log.'**
  String get incidentLogDeleteSelectedBody;

  /// No description provided for @incidentLogDeleteSelectedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select at least one incident to delete'**
  String get incidentLogDeleteSelectedEmpty;

  /// No description provided for @incidentLogSelectedDeleted.
  ///
  /// In en, this message translates to:
  /// **'Selected incidents deleted'**
  String get incidentLogSelectedDeleted;

  /// No description provided for @settingsSourcesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Sources'**
  String get settingsSourcesDialogTitle;

  /// No description provided for @settingsSourcesIntro.
  ///
  /// In en, this message translates to:
  /// **'All emergency procedures are based on verified sources:'**
  String get settingsSourcesIntro;

  /// No description provided for @settingsSourcesRedCrossTitle.
  ///
  /// In en, this message translates to:
  /// **'American Red Cross'**
  String get settingsSourcesRedCrossTitle;

  /// No description provided for @settingsSourcesRedCrossSubtitle.
  ///
  /// In en, this message translates to:
  /// **'First Aid Guidelines'**
  String get settingsSourcesRedCrossSubtitle;

  /// No description provided for @settingsSourcesWHOTitle.
  ///
  /// In en, this message translates to:
  /// **'World Health Organization'**
  String get settingsSourcesWHOTitle;

  /// No description provided for @settingsSourcesWHOSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Care'**
  String get settingsSourcesWHOSubtitle;

  /// No description provided for @settingsSourcesAHATitle.
  ///
  /// In en, this message translates to:
  /// **'American Heart Association'**
  String get settingsSourcesAHATitle;

  /// No description provided for @settingsSourcesAHASubtitle.
  ///
  /// In en, this message translates to:
  /// **'CPR Standards'**
  String get settingsSourcesAHASubtitle;

  /// Israeli emergency medical service. REVIEW: organisation name — confirm Arabic/Hebrew form with stakeholders.
  ///
  /// In en, this message translates to:
  /// **'Magen David Adom'**
  String get settingsSourcesMDATitle;

  /// No description provided for @settingsSourcesMDASubtitle.
  ///
  /// In en, this message translates to:
  /// **'Israeli Protocols'**
  String get settingsSourcesMDASubtitle;

  /// No description provided for @settingsSourcesLastVerified.
  ///
  /// In en, this message translates to:
  /// **'Last verified: January 2026'**
  String get settingsSourcesLastVerified;

  /// No description provided for @settingsAboutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'About Guardian Angel'**
  String get settingsAboutDialogTitle;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get settingsAboutVersion;

  /// No description provided for @settingsAboutDescription.
  ///
  /// In en, this message translates to:
  /// **'An interactive emergency first-aid guide providing step-by-step guidance during medical emergencies.'**
  String get settingsAboutDescription;

  /// No description provided for @settingsAboutDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by:'**
  String get settingsAboutDevelopedBy;

  /// No description provided for @settingsAboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Guardian Angel\nAzrieli College of Engineering'**
  String get settingsAboutCopyright;

  /// No description provided for @disclaimerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency First Aid Guide'**
  String get disclaimerSubtitle;

  /// No description provided for @disclaimerNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT MEDICAL NOTICE'**
  String get disclaimerNoticeTitle;

  /// No description provided for @disclaimerNoticeBody1.
  ///
  /// In en, this message translates to:
  /// **'This application is a decision-support tool and DOES NOT replace professional medical care, diagnosis, or treatment.'**
  String get disclaimerNoticeBody1;

  /// No description provided for @disclaimerNoticeBody2.
  ///
  /// In en, this message translates to:
  /// **'In the event of a life-threatening emergency, always contact your local emergency services (101) immediately.'**
  String get disclaimerNoticeBody2;

  /// No description provided for @disclaimerEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'In Case of Emergency:'**
  String get disclaimerEmergencyTitle;

  /// No description provided for @disclaimerBullet1.
  ///
  /// In en, this message translates to:
  /// **'Call 101 (Magen David Adom) immediately'**
  String get disclaimerBullet1;

  /// No description provided for @disclaimerBullet2.
  ///
  /// In en, this message translates to:
  /// **'Use this app as a guide while waiting for help'**
  String get disclaimerBullet2;

  /// No description provided for @disclaimerBullet3.
  ///
  /// In en, this message translates to:
  /// **'Seek professional medical attention after first aid'**
  String get disclaimerBullet3;

  /// No description provided for @disclaimerSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified Medical Sources'**
  String get disclaimerSourcesTitle;

  /// No description provided for @disclaimerSource1.
  ///
  /// In en, this message translates to:
  /// **'American Red Cross — First Aid Guidelines'**
  String get disclaimerSource1;

  /// No description provided for @disclaimerSource2.
  ///
  /// In en, this message translates to:
  /// **'World Health Organization — Emergency Care'**
  String get disclaimerSource2;

  /// No description provided for @disclaimerSource3.
  ///
  /// In en, this message translates to:
  /// **'American Heart Association — CPR Standards'**
  String get disclaimerSource3;

  /// No description provided for @disclaimerSource4.
  ///
  /// In en, this message translates to:
  /// **'Magen David Adom — Israeli Emergency Protocols'**
  String get disclaimerSource4;

  /// No description provided for @disclaimerAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you acknowledge that this guidance does not replace emergency medical services and that you will call 101 for serious medical situations.'**
  String get disclaimerAcknowledge;

  /// No description provided for @disclaimerVersion.
  ///
  /// In en, this message translates to:
  /// **'Guardian Angel v1.0.0 • Clinical Sentinel UI'**
  String get disclaimerVersion;

  /// No description provided for @disclaimerContinueBtn.
  ///
  /// In en, this message translates to:
  /// **'I UNDERSTAND — CONTINUE'**
  String get disclaimerContinueBtn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
