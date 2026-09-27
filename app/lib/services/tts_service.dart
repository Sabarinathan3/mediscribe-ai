import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'language_provider.dart';

final flutterTtsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage("en-US");
  tts.setSpeechRate(0.5);
  tts.setVolume(1.0);
  tts.setPitch(1.0);
  return tts;
});

enum TtsPlayState { stopped, playing, paused }

class TtsState {
  final TtsPlayState playState;
  final double speed;
  final double volume;
  final String? currentText;

  TtsState({
    this.playState = TtsPlayState.stopped,
    this.speed = 0.5,
    this.volume = 1.0,
    this.currentText,
  });

  TtsState copyWith({
    TtsPlayState? playState,
    double? speed,
    double? volume,
    String? currentText,
  }) {
    return TtsState(
      playState: playState ?? this.playState,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      currentText: currentText ?? this.currentText,
    );
  }
}

class TtsNotifier extends StateNotifier<TtsState> {
  final FlutterTts _tts;
  final Ref _ref;

  TtsNotifier(this._tts, this._ref) : super(TtsState()) {
    _tts.setStartHandler(() {
      state = state.copyWith(playState: TtsPlayState.playing);
    });

    _tts.setCompletionHandler(() {
      state = state.copyWith(playState: TtsPlayState.stopped);
    });

    _tts.setErrorHandler((msg) {
      state = state.copyWith(playState: TtsPlayState.stopped);
    });

    _tts.setCancelHandler(() {
      state = state.copyWith(playState: TtsPlayState.stopped);
    });
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Set appropriate language locale from provider (Tamil, Hindi, Telugu, Malayalam, English)
    final activeLang = _ref.read(languageProvider);
    await _tts.setLanguage(activeLang.locale);
    
    await _tts.setSpeechRate(state.speed);
    await _tts.setVolume(state.volume);
    state = state.copyWith(currentText: text, playState: TtsPlayState.playing);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = state.copyWith(playState: TtsPlayState.stopped);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _tts.setSpeechRate(speed);
  }

  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume);
    await _tts.setVolume(volume);
  }
}

final ttsNotifierProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  final tts = ref.watch(flutterTtsProvider);
  return TtsNotifier(tts, ref);
});
