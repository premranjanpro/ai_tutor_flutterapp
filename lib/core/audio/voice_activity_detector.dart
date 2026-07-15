import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VadState { sleep, idle, speaking, processing }

class VadModel {
  final VadState state;
  final double dbLevel;

  VadModel({required this.state, required this.dbLevel});

  VadModel copyWith({VadState? state, double? dbLevel}) {
    return VadModel(
      state: state ?? this.state,
      dbLevel: dbLevel ?? this.dbLevel,
    );
  }
}

class VoiceActivityDetector extends Notifier<VadModel> {
  Timer? _simulationTimer;
  Timer? _silenceTimer;

  @override
  VadModel build() {
    return VadModel(state: VadState.sleep, dbLevel: 30.0);
  }

  void startVAD() {
    state = VadModel(state: VadState.idle, dbLevel: 30.0);
    _startSimulation();
  }

  void stopVAD() {
    _simulationTimer?.cancel();
    _silenceTimer?.cancel();
    state = VadModel(state: VadState.sleep, dbLevel: 30.0);
  }

  void triggerWakeWord(String word, Function(String) onAction) {
    if (state.state != VadState.sleep) return;
    
    state = state.copyWith(state: VadState.processing);

    // Trigger action based on phrase
    if (word.contains('song')) {
      onAction('play_song');
    } else if (word.contains('movie')) {
      onAction('start_movie');
    } else if (word.contains('rhyme')) {
      onAction('play_rhyme');
    } else {
      onAction('general_wake');
    }

    state = state.copyWith(state: VadState.idle);
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (state.state == VadState.processing) return;

      final sec = DateTime.now().second;
      final isSpeakingSec = (sec % 10 >= 3 && sec % 10 <= 7);

      if (isSpeakingSec) {
        final newDb = 60.0 + (sec % 5) * 4.0;
        state = VadModel(state: VadState.speaking, dbLevel: newDb);
        _silenceTimer?.cancel();
        _silenceTimer = null;
      } else {
        final newDb = 30.0 + (sec % 3) * 3.0;
        state = state.copyWith(dbLevel: newDb);
        
        if (state.state == VadState.speaking) {
          _silenceTimer ??= Timer(const Duration(milliseconds: 1500), () {
            _autoSubmit();
          });
        }
      }
    });
  }

  void _autoSubmit() {
    state = state.copyWith(state: VadState.processing);
    _silenceTimer = null;
    
    // Simulate API delay
    Timer(const Duration(seconds: 2), () {
      state = state.copyWith(state: VadState.idle);
    });
  }
}

final vadProvider = NotifierProvider<VoiceActivityDetector, VadModel>(() {
  return VoiceActivityDetector();
});
