import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Gameplay sound cues. There is intentionally no "wrong answer" sound:
/// incorrect taps only get a soft, neutral cue.
enum SoundCue { tap, success, levelUp, gentleRetry }

/// Abstract audio player so real audio assets can be dropped in later.
abstract class AudioService {
  Future<void> play(SoundCue cue);

  Future<void> dispose() async {}
}

/// Fallback "synthesizer" that uses built-in platform sounds and haptics,
/// so the prototype gives feedback without shipping audio files.
class SynthAudioService implements AudioService {
  const SynthAudioService();

  @override
  Future<void> play(SoundCue cue) async {
    try {
      switch (cue) {
        case SoundCue.tap:
          await SystemSound.play(SystemSoundType.click);
        case SoundCue.success:
          await SystemSound.play(SystemSoundType.click);
          await HapticFeedback.mediumImpact();
        case SoundCue.levelUp:
          await SystemSound.play(SystemSoundType.click);
          await HapticFeedback.heavyImpact();
        case SoundCue.gentleRetry:
          // Neutral, non-punitive: a light tick only, no sound effect.
          await HapticFeedback.selectionClick();
      }
    } catch (e) {
      // Audio is non-essential; never let it interrupt play.
      debugPrint('AudioService: unable to play $cue ($e)');
    }
  }

  @override
  Future<void> dispose() async {}
}

/// Silent implementation that records cues; used in tests and previews.
class MockAudioService implements AudioService {
  final List<SoundCue> played = [];

  @override
  Future<void> play(SoundCue cue) async => played.add(cue);

  @override
  Future<void> dispose() async {}
}
