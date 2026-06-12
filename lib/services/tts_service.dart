import 'package:audioplayers/audioplayers.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final AudioPlayer _player = AudioPlayer();
  String? _lastEmergencyId;
  int? _lastStepIndex;
  String? _lastLangCode;

  static final AudioContext _audioContext = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.speech,
      usageType: AndroidUsageType.assistant,
      audioFocus: AndroidAudioFocus.gain,
    ),
  );

  Future<void> init() async {
    // Configure the playback audio session. Note: on iOS the audio context is
    // global (per-player contexts are ignored), so this applies app-wide.
    await AudioPlayer.global.setAudioContext(_audioContext);
    await _player.setVolume(1.0);
  }

  Future<void> speak(
    String emergencyId,
    int stepIndex,
    String languageCode,
  ) async {
    _lastEmergencyId = emergencyId;
    _lastStepIndex = stepIndex;
    _lastLangCode = languageCode;

    final lang = _langFolder(languageCode);
    final path = 'audio/$lang/$emergencyId/step_$stepIndex.wav';
    try {
      // Re-apply the audio session before playing. This restores playback
      // after the session may have been deactivated by an interruption such
      // as dialing 101 mid-protocol or handing off to a maps app.
      await AudioPlayer.global.setAudioContext(_audioContext);
      await _player.stop();
      await _player.play(AssetSource(path), volume: 1.0);
    } catch (_) {
      // Asset missing or playback failure — fail silently.
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> repeat() async {
    if (_lastEmergencyId != null &&
        _lastStepIndex != null &&
        _lastLangCode != null) {
      await speak(_lastEmergencyId!, _lastStepIndex!, _lastLangCode!);
    }
  }

  /// Maps an app locale code to the voice language code used for audio
  /// lookup. Single source of truth for all screens that trigger playback.
  static String langCodeFor(String locale) => switch (locale) {
    'ar' => 'ar-SA',
    'he' => 'he-IL',
    _ => 'en-US',
  };

  static String _langFolder(String languageCode) {
    switch (languageCode) {
      case 'ar-SA':
        return 'ar';
      case 'he-IL':
        return 'he';
      default:
        return 'en';
    }
  }
}
