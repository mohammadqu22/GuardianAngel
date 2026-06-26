// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'Guardian Angel';

  @override
  String get homeSelectEmergency => 'בחר סוג חירום';

  @override
  String get homeSearchHint => 'חפש חירום...';

  @override
  String get homeSearchHintLearn => 'חפש שיעורים...';

  @override
  String get homeDictationStartTooltip => 'חיפוש קולי';

  @override
  String get homeDictationStopTooltip => 'עצור חיפוש קולי';

  @override
  String get homeDictationUnavailable => 'חיפוש קולי אינו זמין במכשיר זה.';

  @override
  String get homeNoResults => 'לא נמצא חירום';

  @override
  String get homeCallBtn => 'התקשר 101';

  @override
  String get homeCallFailed =>
      'לא ניתן לפתוח את החייגן. אנא התקשר ל-101 ידנית.';

  @override
  String get homeSettingsTooltip => 'הגדרות';

  @override
  String get homePreviousPage => 'הקודם';

  @override
  String get homeNextPage => 'הבא';

  @override
  String homePageIndicator(int current, int total) {
    return 'עמוד $current מתוך $total';
  }

  @override
  String get homeNearbyMedical => 'עזרה רפואית קרובה';

  @override
  String get homeNearbyMedicalSubtitle => 'בתי חולים, בתי מרקחת ומרפאות בסביבה';

  @override
  String get homeModeEmergency => 'חירום';

  @override
  String get homeModeLearn => 'למידה';

  @override
  String get homeLearnTitle => 'תרגול עזרה ראשונה';

  @override
  String get learnNotStarted => 'טרם התחלת';

  @override
  String get learnCompleted => 'הושלם';

  @override
  String learnBestScore(int score, int total) {
    return 'הציון הטוב ביותר: $score/$total';
  }

  @override
  String get learnStartQuiz => 'התחל חידון';

  @override
  String get learnGoToQuiz => 'מעבר לחידון';

  @override
  String get learnReviewLesson => 'חזרה לשיעור';

  @override
  String get learnInProgress => 'בתהליך';

  @override
  String learnAnswered(int answered, int total) {
    return 'נענו $answered מתוך $total';
  }

  @override
  String get learnListen => 'האזנה לשלב הזה';

  @override
  String get quizTitle => 'חידון';

  @override
  String quizQuestionProgress(int current, int total) {
    return 'שאלה $current מתוך $total';
  }

  @override
  String quizQuestionWhichStep(int number) {
    return 'איזה מהבאים הוא שלב $number?';
  }

  @override
  String get quizNext => 'הבא';

  @override
  String get quizFinish => 'סיום';

  @override
  String learnSummary(int completed, int total) {
    return 'הושלמו $completed מתוך $total שיעורים';
  }

  @override
  String quizQuestionAfter(String title) {
    return 'איזה שלב מגיע מיד אחרי: \"$title\"?';
  }

  @override
  String get quizQuestionInstruction => 'לאיזה שלב שייכת ההנחיה הזו?';

  @override
  String get quizCorrect => 'נכון!';

  @override
  String get quizWrong => 'לא מדויק';

  @override
  String get quizFromProtocol => 'מתוך הפרוטוקול:';

  @override
  String get quizReviewTitle => 'סקירת הטעויות שלך';

  @override
  String get quizReviewHint => 'הקישו על פריט כדי לחזור לשלב הזה בפרוטוקול.';

  @override
  String quizYourAnswer(String title) {
    return 'התשובה שלך: $title';
  }

  @override
  String quizCorrectAnswer(String title) {
    return 'התשובה הנכונה: $title';
  }

  @override
  String get quizMedalGold => 'זהב';

  @override
  String get quizMedalSilver => 'כסף';

  @override
  String get quizMedalBronze => 'ארד';

  @override
  String quizAttempt(int number) {
    return 'ניסיון $number';
  }

  @override
  String get quizResultTitle => 'החידון הושלם';

  @override
  String quizResultScore(int score, int total) {
    return 'ענית נכון על $score מתוך $total שאלות.';
  }

  @override
  String get quizRetake => 'חזרה על החידון';

  @override
  String get emergencyChoking => 'חנק';

  @override
  String get emergencyChokingInfant => 'חנק (תינוק)';

  @override
  String get emergencyCPR => 'החייאה';

  @override
  String get emergencyCPRInfant => 'החייאה (תינוק)';

  @override
  String get emergencyBurns => 'כוויות';

  @override
  String get emergencyBleeding => 'דימום';

  @override
  String get emergencyFractures => 'שברים';

  @override
  String get emergencySeizures => 'פרכוסים';

  @override
  String stepProgress(int current, int total) {
    return 'שלב $current מתוך $total';
  }

  @override
  String get stepNext => 'שלב הבא';

  @override
  String get stepDone => 'סיום';

  @override
  String get stepPrevious => 'הקודם';

  @override
  String get stepWarningsBtn => 'צפה באזהרות חשובות';

  @override
  String get stepWarningsTitle => 'אזהרות חשובות';

  @override
  String get stepWarningsGotIt => 'הבנתי';

  @override
  String get stepErrorInvalid =>
      'נתוני הפרוטוקול אינם תקינים. אנא התקן את האפליקציה מחדש.';

  @override
  String get stepErrorFailed =>
      'טעינת הפרוטוקול נכשלה. אנא הפעל מחדש את האפליקציה.';

  @override
  String get stepCompleteTitle => 'הטיפול הושלם';

  @override
  String stepCompleteBody(String emergencyTitle) {
    return 'כל שלבי הפרוטוקול בוצעו בהצלחה עבור $emergencyTitle.';
  }

  @override
  String get stepCompleteVitalsTitle => 'מעקב אחר מדדי המטופל';

  @override
  String get stepCompleteVitalsBody =>
      'שמור על תצפית קלינית. ודא שהמטופל חם והימנע מתנועות פתאומיות עד להגעת הצוות הרפואי.';

  @override
  String get stepCompleteTimingTitle => 'זמני הפרוטוקול';

  @override
  String get stepCompleteTotalTime => 'זמן כולל';

  @override
  String get stepCompleteStartedAt => 'התחלה';

  @override
  String get stepCompleteFinishedAt => 'סיום';

  @override
  String get stepCompleteIncidentLogHint =>
      'אפשר לעיין בסשן הזה מאוחר יותר דרך הגדרות > יומן אירועים.';

  @override
  String get stepCompleteDisclaimer =>
      'אפליקציה זו אינה מחליפה טיפול רפואי מקצועי. פנה לרופא במידת הצורך.';

  @override
  String get stepCompleteBackBtn => 'חזרה לדף הבית';

  @override
  String get stepRepeatAudio => 'חזור על הצליל';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get settingsSubtitle => 'הגדר את העוזר המציל שלך.';

  @override
  String get settingsSectionPreferences => 'העדפות';

  @override
  String get settingsLanguage => 'שפה';

  @override
  String get settingsTheme => 'מצב תצוגה';

  @override
  String get settingsVoiceGuidance => 'הנחיה קולית';

  @override
  String get settingsTtsSubtitle => 'הוראות שמע TTS';

  @override
  String get settingsFreeMode => 'מצב ידיים חופשיות';

  @override
  String get settingsFreeModeSubtitle => 'ניווט קולי ללא ידיים';

  @override
  String get settingsAiDetection => 'זיהוי חירום עם AI';

  @override
  String get settingsAiDetectionSubtitle =>
      'שולח את הטקסט שהוקלד ל-Groq (ענן) כדי להציע פרוטוקול';

  @override
  String get settingsSectionEmergencyContact => 'איש קשר לחירום';

  @override
  String get settingsAddContact => 'הוסף איש קשר לחירום';

  @override
  String get settingsAddContactSubtitle => 'שמור אדם אמין להתקשרות בחירום';

  @override
  String get settingsSectionLocation => 'כלי מיקום';

  @override
  String get settingsShareLocation => 'שתף את מיקומי';

  @override
  String get settingsShareLocationSubtitle => 'עדכונים שוטפים עם שירותי חירום';

  @override
  String get settingsSectionInfo => 'מידע';

  @override
  String get settingsMedicalSources => 'מקורות רפואיים';

  @override
  String get settingsMedicalSourcesSubtitle => 'צפה במקורות המאומתים שלנו';

  @override
  String get settingsIncidentLog => 'יומן אירועים';

  @override
  String get settingsIncidentLogSubtitle =>
      'סקור פרוטוקולי חירום שנפתחו לאחרונה';

  @override
  String get settingsAbout => 'אודות Guardian Angel';

  @override
  String get settingsAboutSubtitle => 'מידע על האפליקציה וגרסה';

  @override
  String get settingsDisclaimerTitle => 'כתב ויתור רפואי';

  @override
  String get settingsDisclaimerBody =>
      'אפליקציה זו היא כלי חינוכי ותומך. היא אינה מחליפה ייעוץ רפואי מקצועי, אבחון או טיפול. תמיד היוועץ ברופאך או בספק בריאות מוסמך אחר לכל שאלה הנוגעת למצב רפואי. במקרה של חירום מסכן חיים, התקשר לשירותי חירום מקומיים מיד.';

  @override
  String get settingsSelectLanguage => 'בחר שפה';

  @override
  String get settingsCancel => 'ביטול';

  @override
  String get settingsClose => 'סגור';

  @override
  String get settingsThemeDialogTitle => 'מצב תצוגה';

  @override
  String get settingsThemeSystem => 'כמו במכשיר';

  @override
  String get settingsThemeLight => 'בהיר';

  @override
  String get settingsThemeDark => 'כהה';

  @override
  String get settingsContactDialogTitle => 'איש קשר לחירום';

  @override
  String get settingsContactName => 'שם';

  @override
  String get settingsContactPhone => 'מספר טלפון';

  @override
  String get settingsContactDelete => 'מחק';

  @override
  String get settingsContactSave => 'שמור';

  @override
  String get settingsContactValidation => 'אנא מלא את שני השדות';

  @override
  String get settingsContactDeleted => 'איש הקשר נמחק';

  @override
  String settingsContactSaved(String name) {
    return '$name נשמר כאיש קשר לחירום';
  }

  @override
  String get settingsCallFailed => 'לא ניתן לפתוח את החייגן';

  @override
  String get settingsCallContactTooltip => 'התקשר לאיש הקשר';

  @override
  String get settingsEditContactTooltip => 'ערוך איש קשר';

  @override
  String get settingsLocationFetching => 'מאחזר מיקום...';

  @override
  String get settingsLocationFailed =>
      'לא ניתן לקבל מיקום. בדוק את הגדרות ה-GPS.';

  @override
  String get settingsLocationDialogTitle => 'המיקום שלי';

  @override
  String get settingsLocationShareHint =>
      'שתף קישור זה עם מישהו כדי להציג את מיקומך:';

  @override
  String settingsLocationCoords(String coords) {
    return 'קואורדינטות: $coords';
  }

  @override
  String get settingsLocationCopy => 'העתק קישור';

  @override
  String get settingsLocationCopied => 'קישור המיקום הועתק! 📋';

  @override
  String get locationShareTitle => 'שתף את מיקומי';

  @override
  String locationShareMessage(String link) {
    return 'אני צריך עזרה! המיקום שלי כרגע: $link';
  }

  @override
  String get locationShareWhatsApp => 'וואטסאפ';

  @override
  String get locationShareSms => 'מסרון';

  @override
  String get locationShareNotAvailable => 'האפליקציה אינה זמינה במכשיר זה';

  @override
  String get nearbyMedicalTitle => 'עזרה רפואית קרובה';

  @override
  String get nearbyMedicalSubtitle =>
      'פתח חיפושים רפואיים קרובים באפליקציית ניווט.';

  @override
  String get nearbyMedicalEmergencyNotice =>
      'בכל חירום מסכן חיים, התקשר קודם ל-101.';

  @override
  String get nearbyMedicalHospitals => 'בתי חולים';

  @override
  String get nearbyMedicalHospitalsSubtitle =>
      'חפש חדרי מיון ובתי חולים קרובים.';

  @override
  String get nearbyMedicalPharmacies => 'בתי מרקחת';

  @override
  String get nearbyMedicalPharmaciesSubtitle =>
      'חפש בתי מרקחת קרובים ואיסוף תרופות.';

  @override
  String get nearbyMedicalClinics => 'מרפאות';

  @override
  String get nearbyMedicalClinicsSubtitle =>
      'חפש מרפאות ומרכזים רפואיים קרובים.';

  @override
  String get nearbyMedicalCheckingLocation => 'בודק את המיקום שלך...';

  @override
  String get nearbyMedicalUsingLocation =>
      'משתמש במיקום הנוכחי שלך לחיפושים קרובים.';

  @override
  String get nearbyMedicalLocationFallback =>
      'המיקום לא זמין. החיפושים עדיין ייפתחו ללא הקואורדינטות שלך.';

  @override
  String get nearbyMedicalRefreshLocation => 'רענן מיקום';

  @override
  String get nearbyMedicalGoogleMaps => 'Google Maps';

  @override
  String get nearbyMedicalWaze => 'Waze';

  @override
  String get nearbyMedicalNavigationFailed => 'לא ניתן לפתוח אפליקציית ניווט.';

  @override
  String get incidentLogTitle => 'יומן אירועים';

  @override
  String incidentLogEntry(String emergencyTitle) {
    return 'נפתח פרוטוקול $emergencyTitle';
  }

  @override
  String incidentLogProgress(int completed, int total) {
    return 'הגעת ל-$completed מתוך $total שלבים';
  }

  @override
  String get incidentLogCompleted => 'כל השלבים הושלמו';

  @override
  String incidentLogTotalTime(String duration) {
    return 'זמן כולל: $duration';
  }

  @override
  String incidentLogStepTimes(String times) {
    return 'זמני שלבים: $times';
  }

  @override
  String get incidentLogStepTimesTitle => 'זמני שלבים';

  @override
  String incidentLogStepTimeLabel(int step) {
    return 'שלב $step';
  }

  @override
  String get incidentLogNoTimingDetails => 'אין פרטי זמן זמינים';

  @override
  String get incidentLogEmptyTitle => 'אין אירועים עדיין';

  @override
  String get incidentLogEmptyBody =>
      'פרוטוקולי חירום שתפתח יופיעו כאן לסקירה מהירה.';

  @override
  String get incidentLogLoadFailed => 'לא ניתן לטעון את יומן האירועים';

  @override
  String get incidentLogLoadFailedBody =>
      'אנא הפעל מחדש את האפליקציה ונסה שוב.';

  @override
  String get incidentLogClearTitle => 'לנקות את יומן האירועים?';

  @override
  String get incidentLogClearBody =>
      'פעולה זו תסיר את כל היסטוריית האירועים השמורה במכשיר זה.';

  @override
  String get incidentLogClearAction => 'נקה';

  @override
  String get incidentLogCleared => 'יומן האירועים נוקה';

  @override
  String get incidentLogClearFailed => 'לא ניתן לנקות את יומן האירועים';

  @override
  String get incidentLogDeleteAction => 'מחק';

  @override
  String get incidentLogDeleteTitle => 'למחוק את האירוע הזה?';

  @override
  String get incidentLogDeleteBody => 'אירוע זה יימחק לצמיתות מהיומן.';

  @override
  String get incidentLogDeleted => 'האירוע נמחק';

  @override
  String get incidentLogDeleteFailed => 'לא ניתן למחוק את האירוע';

  @override
  String get incidentLogSelectAction => 'בחר';

  @override
  String incidentLogSelectionTitle(int count) {
    return '$count נבחרו';
  }

  @override
  String get incidentLogDeleteSelectedTitle => 'למחוק את האירועים שנבחרו?';

  @override
  String get incidentLogDeleteSelectedBody =>
      'האירועים שנבחרו יימחקו לצמיתות מהיומן.';

  @override
  String get incidentLogDeleteSelectedEmpty => 'בחר לפחות אירוע אחד למחיקה';

  @override
  String get incidentLogSelectedDeleted => 'האירועים שנבחרו נמחקו';

  @override
  String get settingsSourcesDialogTitle => 'מקורות רפואיים';

  @override
  String get settingsSourcesIntro =>
      'כל נהלי החירום מבוססים על מקורות מאומתים:';

  @override
  String get settingsSourcesRedCrossTitle => 'הצלב האדום האמריקאי';

  @override
  String get settingsSourcesRedCrossSubtitle => 'הנחיות עזרה ראשונה';

  @override
  String get settingsSourcesWHOTitle => 'ארגון הבריאות העולמי';

  @override
  String get settingsSourcesWHOSubtitle => 'טיפול חירום';

  @override
  String get settingsSourcesAHATitle => 'איגוד הלב האמריקאי';

  @override
  String get settingsSourcesAHASubtitle => 'תקני החייאה';

  @override
  String get settingsSourcesMDATitle => 'מגן דוד אדום';

  @override
  String get settingsSourcesMDASubtitle => 'פרוטוקולי חירום ישראליים';

  @override
  String get settingsSourcesLastVerified => 'אומת לאחרונה: ינואר 2026';

  @override
  String get settingsAboutDialogTitle => 'אודות Guardian Angel';

  @override
  String get settingsAboutVersion => 'גרסה 1.0.0';

  @override
  String get settingsAboutDescription =>
      'מדריך אינטראקטיבי לעזרה ראשונה המספק הנחיות שלב אחר שלב במצבי חירום רפואיים.';

  @override
  String get settingsAboutDevelopedBy => 'פותח על ידי:';

  @override
  String get settingsAboutCopyright =>
      '© 2026 Guardian Angel\nמכללת עזריאלי להנדסה';

  @override
  String get disclaimerSubtitle => 'מדריך עזרה ראשונה בחירום';

  @override
  String get disclaimerNoticeTitle => 'הודעה רפואית חשובה';

  @override
  String get disclaimerNoticeBody1 =>
      'אפליקציה זו היא כלי תמיכה בהחלטות ואינה מחליפה טיפול רפואי מקצועי, אבחון או טיפול.';

  @override
  String get disclaimerNoticeBody2 =>
      'במקרה של חירום מסכן חיים, פנה תמיד לשירותי החירום המקומיים (101) באופן מיידי.';

  @override
  String get disclaimerEmergencyTitle => 'במקרה חירום:';

  @override
  String get disclaimerBullet1 => 'התקשר ל-101 (מגן דוד אדום) מיד';

  @override
  String get disclaimerBullet2 => 'השתמש באפליקציה זו כמדריך בזמן המתנה לעזרה';

  @override
  String get disclaimerBullet3 => 'פנה לטיפול רפואי מקצועי לאחר עזרה ראשונה';

  @override
  String get disclaimerSourcesTitle => 'מקורות רפואיים מאומתים';

  @override
  String get disclaimerSource1 => 'הצלב האדום האמריקאי — הנחיות עזרה ראשונה';

  @override
  String get disclaimerSource2 => 'ארגון הבריאות העולמי — טיפול חירום';

  @override
  String get disclaimerSource3 => 'איגוד הלב האמריקאי — תקני החייאה';

  @override
  String get disclaimerSource4 => 'מגן דוד אדום — פרוטוקולי חירום ישראליים';

  @override
  String get disclaimerAcknowledge =>
      'בהמשך, אתה מאשר שהנחיה זו אינה מחליפה שירותי חירום רפואיים ושתתקשר ל-101 במצבים רפואיים חמורים.';

  @override
  String get disclaimerVersion =>
      'Guardian Angel v1.0.0 • ממשק Clinical Sentinel';

  @override
  String get disclaimerContinueBtn => 'הבנתי — המשך';

  @override
  String get homeAiAnalyzing => 'הבינה המלאכותית מנתחת...';

  @override
  String homeAiDetected(String title) {
    return 'זוהה על ידי AI: $title — הקש לפתיחה';
  }

  @override
  String get stepRestartTitle => 'איפוס הפרוטוקול';

  @override
  String get stepRestartBody => 'פעולה זו תאפס את המדריך לשלב 1. האם אתה בטוח?';

  @override
  String get stepRestartConfirm => 'איפוס';

  @override
  String get stepHandsFreeBanner =>
      'מצב ידיים חופשיות — אמור \"הבא\" או \"אחורה\"';

  @override
  String get stepHandsFreeOn => 'ידיים חופשיות פעיל';

  @override
  String get stepHandsFreeOff => 'ידיים חופשיות כבוי';

  @override
  String get homeAutoPrompt => 'מה מצב החירום שלך? הקש לביטול.';

  @override
  String get homeAiDetectedTitle => 'הבינה המלאכותית זיהתה את מצב החירום שלך';

  @override
  String get homeAiOpenProtocol => 'פתח פרוטוקול';

  @override
  String get homeAiOffline =>
      'הצעות הבינה המלאכותית דורשות חיבור לאינטרנט. עיין ברשימה שלמעלה או התקשר 101.';
}
