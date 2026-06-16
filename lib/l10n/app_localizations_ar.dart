// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Guardian Angel';

  @override
  String get homeSelectEmergency => 'اختر نوع الطارئ';

  @override
  String get homeSearchHint => 'البحث عن طارئ...';

  @override
  String get homeSearchHintLearn => 'البحث في الدروس...';

  @override
  String get homeDictationStartTooltip => 'البحث بالصوت';

  @override
  String get homeDictationStopTooltip => 'إيقاف البحث الصوتي';

  @override
  String get homeDictationUnavailable =>
      'البحث الصوتي غير متاح على هذا الجهاز.';

  @override
  String get homeNoResults => 'لم يُعثر على حالة طوارئ';

  @override
  String get homeCallBtn => 'اتصل بـ 101';

  @override
  String get homeCallFailed => 'تعذر فتح الهاتف. يرجى الاتصال بـ 101 يدويًا.';

  @override
  String get homeSettingsTooltip => 'الإعدادات';

  @override
  String get homePreviousPage => 'السابق';

  @override
  String get homeNextPage => 'التالي';

  @override
  String homePageIndicator(int current, int total) {
    return 'صفحة $current من $total';
  }

  @override
  String get homeNearbyMedical => 'مساعدة طبية قريبة';

  @override
  String get homeNearbyMedicalSubtitle => 'مستشفيات وصيدليات وعيادات قريبة';

  @override
  String get homeModeEmergency => 'طوارئ';

  @override
  String get homeModeLearn => 'تعلّم';

  @override
  String get homeLearnTitle => 'التدرب على الإسعافات الأولية';

  @override
  String get learnNotStarted => 'لم يبدأ بعد';

  @override
  String get learnCompleted => 'مكتمل';

  @override
  String learnBestScore(int score, int total) {
    return 'أفضل نتيجة: $score/$total';
  }

  @override
  String get learnStartQuiz => 'ابدأ الاختبار';

  @override
  String get learnGoToQuiz => 'الانتقال إلى الاختبار';

  @override
  String get learnReviewLesson => 'مراجعة الدرس';

  @override
  String get learnInProgress => 'قيد التقدم';

  @override
  String learnAnswered(int answered, int total) {
    return 'تمت الإجابة على $answered من $total';
  }

  @override
  String get learnListen => 'الاستماع إلى هذه الخطوة';

  @override
  String get quizTitle => 'اختبار';

  @override
  String quizQuestionProgress(int current, int total) {
    return 'السؤال $current من $total';
  }

  @override
  String quizQuestionWhichStep(int number) {
    return 'أي من هذه هي الخطوة رقم $number؟';
  }

  @override
  String get quizNext => 'التالي';

  @override
  String get quizFinish => 'إنهاء';

  @override
  String learnSummary(int completed, int total) {
    return 'اكتمل $completed من $total دروس';
  }

  @override
  String quizQuestionAfter(String title) {
    return 'أي خطوة تأتي مباشرة بعد: \"$title\"؟';
  }

  @override
  String get quizQuestionInstruction => 'إلى أي خطوة تنتمي هذه التعليمات؟';

  @override
  String get quizCorrect => 'إجابة صحيحة!';

  @override
  String get quizWrong => 'ليست الإجابة الصحيحة';

  @override
  String get quizFromProtocol => 'من البروتوكول:';

  @override
  String get quizReviewTitle => 'مراجعة أخطائك';

  @override
  String get quizReviewHint =>
      'اضغط على أي عنصر للعودة إلى تلك الخطوة في البروتوكول.';

  @override
  String quizYourAnswer(String title) {
    return 'إجابتك: $title';
  }

  @override
  String quizCorrectAnswer(String title) {
    return 'الإجابة الصحيحة: $title';
  }

  @override
  String get quizMedalGold => 'ذهبية';

  @override
  String get quizMedalSilver => 'فضية';

  @override
  String get quizMedalBronze => 'برونزية';

  @override
  String quizAttempt(int number) {
    return 'المحاولة $number';
  }

  @override
  String get quizResultTitle => 'اكتمل الاختبار';

  @override
  String quizResultScore(int score, int total) {
    return 'أجبت بشكل صحيح على $score من أصل $total أسئلة.';
  }

  @override
  String get quizRetake => 'إعادة الاختبار';

  @override
  String get emergencyChoking => 'اختناق';

  @override
  String get emergencyChokingInfant => 'اختناق (رضيع)';

  @override
  String get emergencyCPR => 'إنعاش قلبي رئوي';

  @override
  String get emergencyCPRInfant => 'إنعاش قلبي رئوي (رضيع)';

  @override
  String get emergencyBurns => 'حروق';

  @override
  String get emergencyBleeding => 'نزيف';

  @override
  String get emergencyFractures => 'كسور';

  @override
  String get emergencySeizures => 'نوبات';

  @override
  String stepProgress(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get stepNext => 'الخطوة التالية';

  @override
  String get stepDone => 'تم';

  @override
  String get stepPrevious => 'السابق';

  @override
  String get stepWarningsBtn => 'عرض التحذيرات المهمة';

  @override
  String get stepWarningsTitle => 'تحذيرات مهمة';

  @override
  String get stepWarningsGotIt => 'فهمت';

  @override
  String get stepErrorInvalid =>
      'بيانات البروتوكول غير صالحة. يرجى إعادة تثبيت التطبيق.';

  @override
  String get stepErrorFailed =>
      'فشل تحميل البروتوكول. يرجى إعادة تشغيل التطبيق.';

  @override
  String get stepCompleteTitle => 'اكتمل العلاج';

  @override
  String stepCompleteBody(String emergencyTitle) {
    return 'تم تطبيق جميع خطوات البروتوكول بنجاح لـ $emergencyTitle.';
  }

  @override
  String get stepCompleteVitalsTitle => 'مراقبة العلامات الحيوية للمريض';

  @override
  String get stepCompleteVitalsBody =>
      'حافظ على المراقبة السريرية. تأكد من بقاء المريض دافئًا وتجنب الحركات المفاجئة في انتظار وصول الطاقم الطبي.';

  @override
  String get stepCompleteTimingTitle => 'وقت البروتوكول';

  @override
  String get stepCompleteTotalTime => 'الوقت الكلي';

  @override
  String get stepCompleteStartedAt => 'البداية';

  @override
  String get stepCompleteFinishedAt => 'النهاية';

  @override
  String get stepCompleteIncidentLogHint =>
      'يمكنك مراجعة هذه الجلسة لاحقًا من الإعدادات > سجل الحوادث.';

  @override
  String get stepCompleteDisclaimer =>
      'هذا التطبيق لا يُغني عن الرعاية الطبية المتخصصة. استشر طبيبًا عند الحاجة.';

  @override
  String get stepCompleteBackBtn => 'العودة إلى الرئيسية';

  @override
  String get stepRepeatAudio => 'إعادة الصوت';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsSubtitle => 'اضبط مساعدك المنقذ للحياة.';

  @override
  String get settingsSectionPreferences => 'التفضيلات';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsTheme => 'مظهر التطبيق';

  @override
  String get settingsVoiceGuidance => 'التوجيه الصوتي';

  @override
  String get settingsTtsSubtitle => 'تعليمات صوتية TTS';

  @override
  String get settingsFreeMode => 'وضع بدون يدين';

  @override
  String get settingsFreeModeSubtitle => 'تنقل صوتي بدون يدين';

  @override
  String get settingsAiDetection => 'كشف الطوارئ بالذكاء الاصطناعي';

  @override
  String get settingsAiDetectionSubtitle =>
      'يرسل النص المكتوب إلى Groq (سحابة) لاقتراح بروتوكول';

  @override
  String get settingsSectionEmergencyContact => 'جهة اتصال الطوارئ';

  @override
  String get settingsAddContact => 'إضافة جهة اتصال للطوارئ';

  @override
  String get settingsAddContactSubtitle =>
      'احفظ شخصًا موثوقًا للاتصال به في حالات الطوارئ';

  @override
  String get settingsSectionLocation => 'أدوات الموقع';

  @override
  String get settingsShareLocation => 'مشاركة موقعي';

  @override
  String get settingsShareLocationSubtitle => 'تحديثات مباشرة مع خدمات الطوارئ';

  @override
  String get settingsSectionInfo => 'المعلومات';

  @override
  String get settingsMedicalSources => 'المصادر الطبية';

  @override
  String get settingsMedicalSourcesSubtitle => 'عرض مصادرنا الموثقة';

  @override
  String get settingsIncidentLog => 'سجل الحوادث';

  @override
  String get settingsIncidentLogSubtitle =>
      'مراجعة بروتوكولات الطوارئ التي تم فتحها مؤخرًا';

  @override
  String get settingsAbout => 'حول Guardian Angel';

  @override
  String get settingsAboutSubtitle => 'معلومات التطبيق والإصدار';

  @override
  String get settingsDisclaimerTitle => 'إخلاء المسؤولية الطبية';

  @override
  String get settingsDisclaimerBody =>
      'هذا التطبيق أداة تعليمية وداعمة. لا يُعوِّض عن الاستشارة الطبية المتخصصة أو التشخيص أو العلاج. استشر دائمًا طبيبك أو مقدم الرعاية الصحية المؤهل لأي أسئلة تتعلق بحالة طبية. في حالة طوارئ مهددة للحياة، اتصل بخدمات الطوارئ المحلية فورًا.';

  @override
  String get settingsSelectLanguage => 'اختر اللغة';

  @override
  String get settingsCancel => 'إلغاء';

  @override
  String get settingsClose => 'إغلاق';

  @override
  String get settingsThemeDialogTitle => 'مظهر التطبيق';

  @override
  String get settingsThemeSystem => 'افتراضي النظام';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsContactDialogTitle => 'جهة اتصال الطوارئ';

  @override
  String get settingsContactName => 'الاسم';

  @override
  String get settingsContactPhone => 'رقم الهاتف';

  @override
  String get settingsContactDelete => 'حذف';

  @override
  String get settingsContactSave => 'حفظ';

  @override
  String get settingsContactValidation => 'يرجى ملء الحقلين';

  @override
  String get settingsContactDeleted => 'تم حذف جهة الاتصال';

  @override
  String settingsContactSaved(String name) {
    return 'تم حفظ $name كجهة اتصال للطوارئ';
  }

  @override
  String get settingsCallFailed => 'تعذر فتح الهاتف';

  @override
  String get settingsCallContactTooltip => 'الاتصال بجهة الاتصال';

  @override
  String get settingsEditContactTooltip => 'تعديل جهة الاتصال';

  @override
  String get settingsLocationFetching => 'جارٍ تحديد الموقع...';

  @override
  String get settingsLocationFailed =>
      'تعذر الحصول على الموقع. تحقق من إعدادات GPS.';

  @override
  String get settingsLocationDialogTitle => 'موقعي';

  @override
  String get settingsLocationShareHint =>
      'شارك هذا الرابط مع شخص ما لإظهار موقعك:';

  @override
  String settingsLocationCoords(String coords) {
    return 'الإحداثيات: $coords';
  }

  @override
  String get settingsLocationCopy => 'نسخ الرابط';

  @override
  String get settingsLocationCopied => 'تم نسخ رابط الموقع! 📋';

  @override
  String get locationShareTitle => 'مشاركة موقعي';

  @override
  String locationShareMessage(String link) {
    return 'أحتاج إلى مساعدة! موقعي الحالي: $link';
  }

  @override
  String get locationShareWhatsApp => 'واتساب';

  @override
  String get locationShareSms => 'رسالة نصية';

  @override
  String get locationShareNotAvailable => 'التطبيق غير متاح على هذا الجهاز';

  @override
  String get nearbyMedicalTitle => 'مساعدة طبية قريبة';

  @override
  String get nearbyMedicalSubtitle =>
      'افتح عمليات بحث طبية قريبة في تطبيق الملاحة.';

  @override
  String get nearbyMedicalEmergencyNotice =>
      'في أي حالة طوارئ مهددة للحياة، اتصل أولًا بـ 101.';

  @override
  String get nearbyMedicalHospitals => 'مستشفيات';

  @override
  String get nearbyMedicalHospitalsSubtitle =>
      'ابحث عن غرف طوارئ ومستشفيات قريبة.';

  @override
  String get nearbyMedicalPharmacies => 'صيدليات';

  @override
  String get nearbyMedicalPharmaciesSubtitle =>
      'ابحث عن صيدليات قريبة واستلام الأدوية.';

  @override
  String get nearbyMedicalClinics => 'عيادات';

  @override
  String get nearbyMedicalClinicsSubtitle =>
      'ابحث عن عيادات ومراكز طبية قريبة.';

  @override
  String get nearbyMedicalCheckingLocation => 'جارٍ فحص موقعك...';

  @override
  String get nearbyMedicalUsingLocation =>
      'يتم استخدام موقعك الحالي للبحث القريب.';

  @override
  String get nearbyMedicalLocationFallback =>
      'الموقع غير متاح. سيتم فتح البحث بدون إحداثياتك.';

  @override
  String get nearbyMedicalRefreshLocation => 'تحديث الموقع';

  @override
  String get nearbyMedicalGoogleMaps => 'Google Maps';

  @override
  String get nearbyMedicalWaze => 'Waze';

  @override
  String get nearbyMedicalNavigationFailed => 'تعذر فتح تطبيق الملاحة.';

  @override
  String get incidentLogTitle => 'سجل الحوادث';

  @override
  String incidentLogEntry(String emergencyTitle) {
    return 'تم فتح بروتوكول $emergencyTitle';
  }

  @override
  String incidentLogProgress(int completed, int total) {
    return 'تم الوصول إلى $completed من $total خطوات';
  }

  @override
  String get incidentLogCompleted => 'تم إكمال جميع الخطوات';

  @override
  String incidentLogTotalTime(String duration) {
    return 'الوقت الكلي: $duration';
  }

  @override
  String incidentLogStepTimes(String times) {
    return 'أوقات الخطوات: $times';
  }

  @override
  String get incidentLogStepTimesTitle => 'أوقات الخطوات';

  @override
  String incidentLogStepTimeLabel(int step) {
    return 'الخطوة $step';
  }

  @override
  String get incidentLogNoTimingDetails => 'لا توجد تفاصيل وقت متاحة';

  @override
  String get incidentLogEmptyTitle => 'لا توجد حوادث بعد';

  @override
  String get incidentLogEmptyBody =>
      'ستظهر هنا بروتوكولات الطوارئ التي تفتحها للمراجعة السريعة.';

  @override
  String get incidentLogLoadFailed => 'تعذر تحميل سجل الحوادث';

  @override
  String get incidentLogLoadFailedBody =>
      'يرجى إعادة تشغيل التطبيق والمحاولة مرة أخرى.';

  @override
  String get incidentLogClearTitle => 'مسح سجل الحوادث؟';

  @override
  String get incidentLogClearBody =>
      'سيؤدي هذا إلى إزالة كل سجل الحوادث المحفوظ على هذا الجهاز.';

  @override
  String get incidentLogClearAction => 'مسح';

  @override
  String get incidentLogCleared => 'تم مسح سجل الحوادث';

  @override
  String get incidentLogClearFailed => 'تعذر مسح سجل الحوادث';

  @override
  String get incidentLogDeleteAction => 'حذف';

  @override
  String get incidentLogDeleteTitle => 'حذف هذا السجل؟';

  @override
  String get incidentLogDeleteBody =>
      'سيتم حذف هذا السجل نهائيًا من قائمة السجلات.';

  @override
  String get incidentLogDeleted => 'تم حذف السجل';

  @override
  String get incidentLogDeleteFailed => 'تعذر حذف السجل';

  @override
  String get incidentLogSelectAction => 'تحديد';

  @override
  String incidentLogSelectionTitle(int count) {
    return 'تم تحديد $count';
  }

  @override
  String get incidentLogDeleteSelectedTitle => 'حذف السجلات المحددة؟';

  @override
  String get incidentLogDeleteSelectedBody =>
      'سيتم حذف السجلات المحددة نهائيًا من قائمة السجلات.';

  @override
  String get incidentLogDeleteSelectedEmpty =>
      'حدد سجلًا واحدًا على الأقل لحذفه';

  @override
  String get incidentLogSelectedDeleted => 'تم حذف السجلات المحددة';

  @override
  String get settingsSourcesDialogTitle => 'المصادر الطبية';

  @override
  String get settingsSourcesIntro =>
      'جميع إجراءات الطوارئ مستندة إلى مصادر موثقة:';

  @override
  String get settingsSourcesRedCrossTitle => 'الصليب الأحمر الأمريكي';

  @override
  String get settingsSourcesRedCrossSubtitle => 'إرشادات الإسعافات الأولية';

  @override
  String get settingsSourcesWHOTitle => 'منظمة الصحة العالمية';

  @override
  String get settingsSourcesWHOSubtitle => 'رعاية الطوارئ';

  @override
  String get settingsSourcesAHATitle => 'جمعية القلب الأمريكية';

  @override
  String get settingsSourcesAHASubtitle => 'معايير الإنعاش القلبي الرئوي';

  @override
  String get settingsSourcesMDATitle => 'نجمة داوود الحمراء';

  @override
  String get settingsSourcesMDASubtitle => 'بروتوكولات الطوارئ الإسرائيلية';

  @override
  String get settingsSourcesLastVerified => 'آخر تحقق: يناير 2026';

  @override
  String get settingsAboutDialogTitle => 'حول Guardian Angel';

  @override
  String get settingsAboutVersion => 'الإصدار 1.0.0';

  @override
  String get settingsAboutDescription =>
      'دليل تفاعلي للإسعافات الأولية يوفر إرشادات خطوة بخطوة خلال حالات الطوارئ الطبية.';

  @override
  String get settingsAboutDevelopedBy => 'طُوِّر بواسطة:';

  @override
  String get settingsAboutCopyright =>
      '© 2026 Guardian Angel\nكلية عزرائيلي للهندسة';

  @override
  String get disclaimerSubtitle => 'دليل الإسعافات الأولية';

  @override
  String get disclaimerNoticeTitle => 'إشعار طبي مهم';

  @override
  String get disclaimerNoticeBody1 =>
      'هذا التطبيق أداة لدعم القرار ولا يُعوِّض عن الرعاية الطبية المتخصصة أو التشخيص أو العلاج.';

  @override
  String get disclaimerNoticeBody2 =>
      'في حالة الطوارئ المهددة للحياة، اتصل دائمًا بخدمات الطوارئ المحلية (101) فورًا.';

  @override
  String get disclaimerEmergencyTitle => 'في حالة الطوارئ:';

  @override
  String get disclaimerBullet1 => 'اتصل بـ 101 (نجمة داوود الحمراء) فورًا';

  @override
  String get disclaimerBullet2 =>
      'استخدم هذا التطبيق دليلًا أثناء انتظار المساعدة';

  @override
  String get disclaimerBullet3 => 'اطلب رعاية طبية متخصصة بعد الإسعاف الأولي';

  @override
  String get disclaimerSourcesTitle => 'مصادر طبية موثقة';

  @override
  String get disclaimerSource1 =>
      'الصليب الأحمر الأمريكي — إرشادات الإسعافات الأولية';

  @override
  String get disclaimerSource2 => 'منظمة الصحة العالمية — رعاية الطوارئ';

  @override
  String get disclaimerSource3 =>
      'جمعية القلب الأمريكية — معايير الإنعاش القلبي الرئوي';

  @override
  String get disclaimerSource4 =>
      'نجمة داوود الحمراء — بروتوكولات الطوارئ الإسرائيلية';

  @override
  String get disclaimerAcknowledge =>
      'بالمتابعة، تُقر بأن هذه الإرشادات لا تُعوِّض عن خدمات الطوارئ الطبية وأنك ستتصل بـ 101 في الحالات الطبية الخطيرة.';

  @override
  String get disclaimerVersion =>
      'Guardian Angel v1.0.0 • واجهة Clinical Sentinel';

  @override
  String get disclaimerContinueBtn => 'أفهم — متابعة';

  @override
  String get homeAiAnalyzing => 'الذكاء الاصطناعي يحلل...';

  @override
  String homeAiDetected(String title) {
    return 'اكتشف الذكاء الاصطناعي: $title — اضغط للفتح';
  }

  @override
  String get stepRestartTitle => 'إعادة تشغيل البروتوكول';

  @override
  String get stepRestartBody =>
      'سيؤدي هذا إلى إعادة تشغيل الدليل من الخطوة 1. هل أنت متأكد؟';

  @override
  String get stepRestartConfirm => 'إعادة تشغيل';

  @override
  String get stepHandsFreeBanner =>
      'الوضع الحر نشط — قل \"التالي\" أو \"السابق\"';

  @override
  String get stepHandsFreeOn => 'الوضع الحر مفعّل';

  @override
  String get stepHandsFreeOff => 'الوضع الحر معطّل';

  @override
  String get homeAutoPrompt => 'ما هي حالتك الطارئة؟ اضغط للإلغاء.';

  @override
  String get homeAiDetectedTitle => 'اكتشف الذكاء الاصطناعي حالتك الطارئة';

  @override
  String get homeAiOpenProtocol => 'فتح البروتوكول';
}
