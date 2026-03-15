import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  // final AudioPlayer _player = AudioPlayer(); // Stubbed for MVP

  Future<void> init() async {
    // Pre-load assets for zero latency
    // In a real app we'd load an actual whoosh.mp3 from assets/audio
    // await _player.setSource(AssetSource('audio/whoosh.mp3'));
  }

  Future<void> playWhoosh() async {
    // Fire and forget sound
    // await _player.resume();
    
    // NOTE: Audio player stubbed out because we need actual sound files.
    // In actual implementation: await _player.play(AssetSource('audio/whoosh.mp3'));
  }
}
