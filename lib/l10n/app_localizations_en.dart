// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Guardian Angel';

  @override
  String get homeSelectEmergency => 'Select Emergency Type';

  @override
  String get homeSearchHint => 'Search emergency...';

  @override
  String get homeSearchHintLearn => 'Search lessons...';

  @override
  String get homeDictationStartTooltip => 'Search by voice';

  @override
  String get homeDictationStopTooltip => 'Stop voice search';

  @override
  String get homeDictationUnavailable =>
      'Voice search is unavailable on this device.';

  @override
  String get homeNoResults => 'No emergency found';

  @override
  String get homeCallBtn => 'CALL 101';

  @override
  String get homeCallFailed =>
      'Could not open dialer. Please call 101 manually.';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get homePreviousPage => 'Previous';

  @override
  String get homeNextPage => 'Next';

  @override
  String homePageIndicator(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get homeNearbyMedical => 'Nearby Medical Help';

  @override
  String get homeNearbyMedicalSubtitle =>
      'Hospitals, pharmacies, and clinics nearby';

  @override
  String get homeModeEmergency => 'Emergency';

  @override
  String get homeModeLearn => 'Learn';

  @override
  String get homeLearnTitle => 'Practice First Aid';

  @override
  String get learnNotStarted => 'Not started';

  @override
  String get learnCompleted => 'Completed';

  @override
  String learnBestScore(int score, int total) {
    return 'Best score: $score/$total';
  }

  @override
  String get learnStartQuiz => 'START QUIZ';

  @override
  String get learnGoToQuiz => 'Go to quiz';

  @override
  String get learnReviewLesson => 'Review lesson';

  @override
  String get learnInProgress => 'In progress';

  @override
  String learnAnswered(int answered, int total) {
    return '$answered of $total answered';
  }

  @override
  String get learnListen => 'Listen to this step';

  @override
  String get quizTitle => 'Quiz';

  @override
  String quizQuestionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String quizQuestionWhichStep(int number) {
    return 'Which of these is step $number?';
  }

  @override
  String get quizNext => 'NEXT';

  @override
  String get quizFinish => 'FINISH';

  @override
  String learnSummary(int completed, int total) {
    return '$completed of $total lessons completed';
  }

  @override
  String quizQuestionAfter(String title) {
    return 'Which step comes right after: \"$title\"?';
  }

  @override
  String get quizQuestionInstruction =>
      'Which step does this instruction belong to?';

  @override
  String get quizCorrect => 'Correct!';

  @override
  String get quizWrong => 'Not quite';

  @override
  String get quizFromProtocol => 'From the protocol:';

  @override
  String get quizReviewTitle => 'Review your misses';

  @override
  String get quizReviewHint =>
      'Tap an item to revisit that step of the protocol.';

  @override
  String quizYourAnswer(String title) {
    return 'Your answer: $title';
  }

  @override
  String quizCorrectAnswer(String title) {
    return 'Correct answer: $title';
  }

  @override
  String get quizMedalGold => 'Gold';

  @override
  String get quizMedalSilver => 'Silver';

  @override
  String get quizMedalBronze => 'Bronze';

  @override
  String quizAttempt(int number) {
    return 'Attempt $number';
  }

  @override
  String get quizResultTitle => 'QUIZ COMPLETE';

  @override
  String quizResultScore(int score, int total) {
    return 'You answered $score of $total questions correctly.';
  }

  @override
  String get quizRetake => 'RETAKE QUIZ';

  @override
  String get emergencyChoking => 'Choking';

  @override
  String get emergencyChokingInfant => 'Choking (Infant)';

  @override
  String get emergencyCPR => 'CPR';

  @override
  String get emergencyCPRInfant => 'CPR (Infant)';

  @override
  String get emergencyBurns => 'Burns';

  @override
  String get emergencyBleeding => 'Bleeding';

  @override
  String get emergencyFractures => 'Fractures';

  @override
  String get emergencySeizures => 'Seizures';

  @override
  String stepProgress(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get stepNext => 'NEXT STEP';

  @override
  String get stepDone => 'DONE';

  @override
  String get stepPrevious => 'Previous';

  @override
  String get stepWarningsBtn => 'View important warnings';

  @override
  String get stepWarningsTitle => 'IMPORTANT WARNINGS';

  @override
  String get stepWarningsGotIt => 'GOT IT';

  @override
  String get stepErrorInvalid =>
      'Protocol data is invalid. Please reinstall the app.';

  @override
  String get stepErrorFailed =>
      'Failed to load protocol. Please restart the app.';

  @override
  String get stepCompleteTitle => 'TREATMENT COMPLETE';

  @override
  String stepCompleteBody(String emergencyTitle) {
    return 'All protocol steps have been successfully administered for $emergencyTitle.';
  }

  @override
  String get stepCompleteVitalsTitle => 'Monitor Patient Vitals';

  @override
  String get stepCompleteVitalsBody =>
      'Maintain clinical observation. Ensure the patient remains warm and avoid sudden movements while waiting for medical staff arrival.';

  @override
  String get stepCompleteTimingTitle => 'Protocol Timing';

  @override
  String get stepCompleteTotalTime => 'Total time';

  @override
  String get stepCompleteStartedAt => 'Started';

  @override
  String get stepCompleteFinishedAt => 'Finished';

  @override
  String get stepCompleteIncidentLogHint =>
      'You can review this session later in Settings > Incident Log.';

  @override
  String get stepCompleteDisclaimer =>
      'This app does not replace professional medical care. Seek a doctor if needed.';

  @override
  String get stepCompleteBackBtn => 'BACK TO HOME';

  @override
  String get stepRepeatAudio => 'Repeat audio';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Configure your life-saving assistant.';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'App Theme';

  @override
  String get settingsVoiceGuidance => 'Voice Guidance';

  @override
  String get settingsTtsSubtitle => 'TTS Audio Instructions';

  @override
  String get settingsFreeMode => 'Free Mode';

  @override
  String get settingsFreeModeSubtitle => 'Hands-free voice navigation';

  @override
  String get settingsAiDetection => 'AI Emergency Detection';

  @override
  String get settingsAiDetectionSubtitle =>
      'Sends typed text to Groq (cloud) to suggest a protocol';

  @override
  String get settingsSectionEmergencyContact => 'Emergency Contact';

  @override
  String get settingsAddContact => 'Add Emergency Contact';

  @override
  String get settingsAddContactSubtitle =>
      'Save a trusted person to call in emergencies';

  @override
  String get settingsSectionLocation => 'Location Tools';

  @override
  String get settingsShareLocation => 'Share My Location';

  @override
  String get settingsShareLocationSubtitle =>
      'Live updates with emergency services';

  @override
  String get settingsSectionInfo => 'Information';

  @override
  String get settingsMedicalSources => 'Medical Sources';

  @override
  String get settingsMedicalSourcesSubtitle => 'View our verified sources';

  @override
  String get settingsIncidentLog => 'Incident Log';

  @override
  String get settingsIncidentLogSubtitle =>
      'Review recently opened emergency protocols';

  @override
  String get settingsAbout => 'About Guardian Angel';

  @override
  String get settingsAboutSubtitle => 'App information & version';

  @override
  String get settingsDisclaimerTitle => 'Medical Disclaimer';

  @override
  String get settingsDisclaimerBody =>
      'This application is an educational and supportive tool. It does not replace professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions regarding a medical condition. In case of a life-threatening emergency, call your local emergency services immediately.';

  @override
  String get settingsSelectLanguage => 'Select Language';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsClose => 'Close';

  @override
  String get settingsThemeDialogTitle => 'App Theme';

  @override
  String get settingsThemeSystem => 'System Default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsContactDialogTitle => 'Emergency Contact';

  @override
  String get settingsContactName => 'Name';

  @override
  String get settingsContactPhone => 'Phone Number';

  @override
  String get settingsContactDelete => 'Delete';

  @override
  String get settingsContactSave => 'SAVE';

  @override
  String get settingsContactValidation => 'Please fill in both fields';

  @override
  String get settingsContactDeleted => 'Contact deleted';

  @override
  String settingsContactSaved(String name) {
    return '$name saved as emergency contact';
  }

  @override
  String get settingsCallFailed => 'Could not open dialer';

  @override
  String get settingsCallContactTooltip => 'Call contact';

  @override
  String get settingsEditContactTooltip => 'Edit contact';

  @override
  String get settingsLocationFetching => 'Fetching location...';

  @override
  String get settingsLocationFailed =>
      'Could not get location. Check GPS settings.';

  @override
  String get settingsLocationDialogTitle => 'My Location';

  @override
  String get settingsLocationShareHint =>
      'Share this link with someone to show your location:';

  @override
  String settingsLocationCoords(String coords) {
    return 'Coordinates: $coords';
  }

  @override
  String get settingsLocationCopy => 'Copy Link';

  @override
  String get settingsLocationCopied => 'Location link copied! 📋';

  @override
  String get locationShareTitle => 'Share My Location';

  @override
  String locationShareMessage(String link) {
    return 'I need help! My current location: $link';
  }

  @override
  String get locationShareWhatsApp => 'WhatsApp';

  @override
  String get locationShareSms => 'SMS';

  @override
  String get locationShareNotAvailable => 'App not available on this device';

  @override
  String get nearbyMedicalTitle => 'Nearby Medical Help';

  @override
  String get nearbyMedicalSubtitle =>
      'Open nearby medical searches in your navigation app.';

  @override
  String get nearbyMedicalEmergencyNotice =>
      'Call 101 first for any life-threatening emergency.';

  @override
  String get nearbyMedicalHospitals => 'Hospitals';

  @override
  String get nearbyMedicalHospitalsSubtitle =>
      'Search for nearby emergency rooms and hospitals.';

  @override
  String get nearbyMedicalPharmacies => 'Pharmacies';

  @override
  String get nearbyMedicalPharmaciesSubtitle =>
      'Search for nearby pharmacies and medicine pickup.';

  @override
  String get nearbyMedicalClinics => 'Clinics';

  @override
  String get nearbyMedicalClinicsSubtitle =>
      'Search for nearby clinics and medical centers.';

  @override
  String get nearbyMedicalCheckingLocation => 'Checking your location...';

  @override
  String get nearbyMedicalUsingLocation =>
      'Using your current location for nearby searches.';

  @override
  String get nearbyMedicalLocationFallback =>
      'Location is unavailable. Searches will still open without your coordinates.';

  @override
  String get nearbyMedicalRefreshLocation => 'Refresh location';

  @override
  String get nearbyMedicalGoogleMaps => 'Google Maps';

  @override
  String get nearbyMedicalWaze => 'Waze';

  @override
  String get nearbyMedicalNavigationFailed =>
      'Navigation app could not be opened.';

  @override
  String get incidentLogTitle => 'Incident Log';

  @override
  String incidentLogEntry(String emergencyTitle) {
    return 'Opened $emergencyTitle protocol';
  }

  @override
  String incidentLogProgress(int completed, int total) {
    return '$completed of $total steps reached';
  }

  @override
  String get incidentLogCompleted => 'Completed all steps';

  @override
  String incidentLogTotalTime(String duration) {
    return 'Total time: $duration';
  }

  @override
  String incidentLogStepTimes(String times) {
    return 'Step times: $times';
  }

  @override
  String get incidentLogStepTimesTitle => 'Step times';

  @override
  String incidentLogStepTimeLabel(int step) {
    return 'Step $step';
  }

  @override
  String get incidentLogNoTimingDetails => 'No timing details available';

  @override
  String get incidentLogEmptyTitle => 'No incidents yet';

  @override
  String get incidentLogEmptyBody =>
      'Opened emergency protocols will appear here for quick review.';

  @override
  String get incidentLogLoadFailed => 'Could not load incident log';

  @override
  String get incidentLogLoadFailedBody =>
      'Please restart the app and try again.';

  @override
  String get incidentLogClearTitle => 'Clear incident log?';

  @override
  String get incidentLogClearBody =>
      'This removes all saved incident history from this device.';

  @override
  String get incidentLogClearAction => 'Clear';

  @override
  String get incidentLogCleared => 'Incident log cleared';

  @override
  String get incidentLogClearFailed => 'Could not clear incident log';

  @override
  String get incidentLogDeleteAction => 'Delete';

  @override
  String get incidentLogDeleteTitle => 'Delete this incident?';

  @override
  String get incidentLogDeleteBody =>
      'This incident will be permanently removed from the log.';

  @override
  String get incidentLogDeleted => 'Incident deleted';

  @override
  String get incidentLogDeleteFailed => 'Could not delete incident';

  @override
  String get incidentLogSelectAction => 'Select';

  @override
  String incidentLogSelectionTitle(int count) {
    return '$count selected';
  }

  @override
  String get incidentLogDeleteSelectedTitle => 'Delete selected incidents?';

  @override
  String get incidentLogDeleteSelectedBody =>
      'The selected incidents will be permanently removed from the log.';

  @override
  String get incidentLogDeleteSelectedEmpty =>
      'Select at least one incident to delete';

  @override
  String get incidentLogSelectedDeleted => 'Selected incidents deleted';

  @override
  String get settingsSourcesDialogTitle => 'Medical Sources';

  @override
  String get settingsSourcesIntro =>
      'All emergency procedures are based on verified sources:';

  @override
  String get settingsSourcesRedCrossTitle => 'American Red Cross';

  @override
  String get settingsSourcesRedCrossSubtitle => 'First Aid Guidelines';

  @override
  String get settingsSourcesWHOTitle => 'World Health Organization';

  @override
  String get settingsSourcesWHOSubtitle => 'Emergency Care';

  @override
  String get settingsSourcesAHATitle => 'American Heart Association';

  @override
  String get settingsSourcesAHASubtitle => 'CPR Standards';

  @override
  String get settingsSourcesMDATitle => 'Magen David Adom';

  @override
  String get settingsSourcesMDASubtitle => 'Israeli Protocols';

  @override
  String get settingsSourcesLastVerified => 'Last verified: January 2026';

  @override
  String get settingsAboutDialogTitle => 'About Guardian Angel';

  @override
  String get settingsAboutVersion => 'Version 1.0.0';

  @override
  String get settingsAboutDescription =>
      'An interactive emergency first-aid guide providing step-by-step guidance during medical emergencies.';

  @override
  String get settingsAboutDevelopedBy => 'Developed by:';

  @override
  String get settingsAboutCopyright =>
      '© 2026 Guardian Angel\nAzrieli College of Engineering';

  @override
  String get disclaimerSubtitle => 'Emergency First Aid Guide';

  @override
  String get disclaimerNoticeTitle => 'IMPORTANT MEDICAL NOTICE';

  @override
  String get disclaimerNoticeBody1 =>
      'This application is a decision-support tool and DOES NOT replace professional medical care, diagnosis, or treatment.';

  @override
  String get disclaimerNoticeBody2 =>
      'In the event of a life-threatening emergency, always contact your local emergency services (101) immediately.';

  @override
  String get disclaimerEmergencyTitle => 'In Case of Emergency:';

  @override
  String get disclaimerBullet1 => 'Call 101 (Magen David Adom) immediately';

  @override
  String get disclaimerBullet2 =>
      'Use this app as a guide while waiting for help';

  @override
  String get disclaimerBullet3 =>
      'Seek professional medical attention after first aid';

  @override
  String get disclaimerSourcesTitle => 'Verified Medical Sources';

  @override
  String get disclaimerSource1 => 'American Red Cross — First Aid Guidelines';

  @override
  String get disclaimerSource2 => 'World Health Organization — Emergency Care';

  @override
  String get disclaimerSource3 => 'American Heart Association — CPR Standards';

  @override
  String get disclaimerSource4 =>
      'Magen David Adom — Israeli Emergency Protocols';

  @override
  String get disclaimerAcknowledge =>
      'By continuing, you acknowledge that this guidance does not replace emergency medical services and that you will call 101 for serious medical situations.';

  @override
  String get disclaimerVersion =>
      'Guardian Angel v1.0.0 • Clinical Sentinel UI';

  @override
  String get disclaimerContinueBtn => 'I UNDERSTAND — CONTINUE';

  @override
  String get homeAiAnalyzing => 'AI is analyzing...';

  @override
  String homeAiDetected(String title) {
    return 'AI detected: $title — tap to open';
  }

  @override
  String get stepRestartTitle => 'Restart Protocol';

  @override
  String get stepRestartBody =>
      'This will restart the guide from Step 1. Are you sure?';

  @override
  String get stepRestartConfirm => 'Restart';

  @override
  String get stepHandsFreeBanner =>
      'Hands-free active — say \"Next\" or \"Back\"';

  @override
  String get stepHandsFreeOn => 'Hands-free ON';

  @override
  String get stepHandsFreeOff => 'Hands-free OFF';

  @override
  String get homeAutoPrompt => 'What is your emergency? Tap to dismiss.';

  @override
  String get homeAiDetectedTitle => 'AI detected your emergency';

  @override
  String get homeAiOpenProtocol => 'OPEN PROTOCOL';

  @override
  String get homeAiOffline =>
      'AI suggestions need an internet connection. Browse the list above, or call 101.';
}
