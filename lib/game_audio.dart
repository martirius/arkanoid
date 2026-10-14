import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

enum GameSound {
  ballHitBlock('ball_hit_block.wav', players: 6),
  ballHitBlockUnbreakable('ball_hit_block_unbreakable.wav', players: 3),
  ballHitStarship('ball_hit_starship.wav', players: 3),
  starshipShoot('starship_shoot.wav', players: 3),
  alienHit('alien_hit.wav', players: 3),
  starshipExtends('starship_extends.wav'),
  ballGoDown('ball_go_down.wav'),
  wallPortalTook('wall_portal_took.wav'),
  extraLife('extra_life.wav'),
  dohDeath('doh_death.wav'),
  dohStart('Dimensional_Fortress_Doh.mp3', mode: PlayerMode.mediaPlayer),
  gameStart('Game_Start.mp3', mode: PlayerMode.mediaPlayer),
  gameOver('Game_Over.mp3', mode: PlayerMode.mediaPlayer);

  const GameSound(
    this.fileName, {
    this.players = 1,
    this.mode = PlayerMode.lowLatency,
  });

  final String fileName;
  final int players;
  final PlayerMode mode;
}

class GameAudio {
  final Map<GameSound, List<AudioPlayer>> _players = {};
  final Map<GameSound, int> _nextPlayer = {};
  final Map<AudioPlayer, Future<void>> _operations = {};
  bool _disposed = false;

  Future<void> load() async {
    final audioContext = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();

    await Future.wait(GameSound.values.map((sound) async {
      final players = <AudioPlayer>[];
      // Android SoundPool assigns the shared sound id only after the first
      // player finishes loading, so players for the same file must be serial.
      for (var index = 0; index < sound.players; index++) {
        players.add(await _createPlayer(sound, audioContext));
      }
      _players[sound] = players;
      _nextPlayer[sound] = 0;
    }));
  }

  Future<AudioPlayer> _createPlayer(
    GameSound sound,
    AudioContext audioContext,
  ) async {
    final player = AudioPlayer()
      ..audioCache = FlameAudio.audioCache
      // The game does not display playback progress, so per-frame polling is
      // unnecessary work on the main isolate.
      ..positionUpdater = null;
    await player.setAudioContext(audioContext);
    await player.setPlayerMode(sound.mode);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(sound.fileName));
    return player;
  }

  void play(GameSound sound) {
    if (_disposed) {
      return;
    }

    final players = _players[sound];
    if (players == null || players.isEmpty) {
      return;
    }

    final index = _nextPlayer[sound] ?? 0;
    final player = players[index];
    _nextPlayer[sound] = (index + 1) % players.length;

    final operation = (_operations[player] ?? Future<void>.value())
        .then((_) => _restart(player));
    _operations[player] = operation;
    unawaited(operation);
  }

  Future<void> _restart(AudioPlayer player) async {
    try {
      await player.stop();
      await player.resume();
    } catch (error, stackTrace) {
      debugPrint('Unable to play game audio: $error\n$stackTrace');
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;

    await Future.wait(_operations.values);
    await Future.wait(
      _players.values
          .expand((players) => players)
          .map((player) => player.dispose()),
    );
    _players.clear();
    _nextPlayer.clear();
    _operations.clear();
  }
}
