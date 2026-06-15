import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class TtsService {
  TtsService._() {
    // Surface natural playback completion to listeners (e.g. the step screen
    // re-opens the mic for hands-free commands once narration finishes).
    _player.onPlayerComplete.listen((_) => _completeController.add(null));
  }
  static final TtsService instance = TtsService._();

  final AudioPlayer _player = AudioPlayer();
  final StreamController<void> _completeController =
      StreamController<void>.broadcast();
  String? _lastEmergencyId;
  int? _lastStepIndex;
  String? _lastLangCode;

  /// Fires whenever a step finishes narrating — including when playback fails
  /// (missing asset), so listeners never hang waiting for a step that will
  /// never complete.
  Stream<void> get onComplete => _completeController.stream;

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
      // Asset missing or playback failure — fail silently, but still signal
      // completion so hands-free listening resumes instead of hanging.
      _completeController.add(null);
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
