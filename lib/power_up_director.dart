import 'dart:math';

import 'package:arkanoid/components/power_up.dart';

typedef RandomInt = int Function(int max);

class PowerUpDirector {
  PowerUpDirector({RandomInt? randomInt})
      : _randomInt = randomInt ?? Random().nextInt;

  static const _defaultTypes = [
    PowerUpType.slow,
    PowerUpType.cattch,
    PowerUpType.extend,
    PowerUpType.disrupt,
    PowerUpType.laser,
    PowerUpType.cattch,
    PowerUpType.disrupt,
    PowerUpType.extend,
  ];
  static const _withoutCatch = [
    PowerUpType.slow,
    PowerUpType.extend,
    PowerUpType.disrupt,
    PowerUpType.laser,
    PowerUpType.extend,
    PowerUpType.laser,
    PowerUpType.slow,
    PowerUpType.disrupt,
  ];
  static const _withoutExtend = [
    PowerUpType.slow,
    PowerUpType.cattch,
    PowerUpType.disrupt,
    PowerUpType.laser,
    PowerUpType.cattch,
    PowerUpType.laser,
    PowerUpType.disrupt,
    PowerUpType.slow,
  ];
  static const _withoutLaser = [
    PowerUpType.slow,
    PowerUpType.cattch,
    PowerUpType.extend,
    PowerUpType.disrupt,
    PowerUpType.cattch,
    PowerUpType.disrupt,
    PowerUpType.slow,
    PowerUpType.extend,
  ];

  final RandomInt _randomInt;
  int _capsulesLeftInBreakCycle = 0;
  int _breakCountdown = 0;
  int _playerLowCounter = 0;
  int _playerHighCounter = 0;

  PowerUpType? select({
    required PowerUpType? activePowerUp,
    required bool hasFallingCapsule,
    required bool hasMultipleBalls,
    required bool portalOpen,
    required int breakableBricksRemaining,
    required bool playerAlreadyAwarded,
  }) {
    if (hasFallingCapsule ||
        hasMultipleBalls ||
        portalOpen ||
        breakableBricksRemaining < 4) {
      return null;
    }

    if (_shouldSpawnBreak()) {
      return PowerUpType.break_;
    }
    if (!playerAlreadyAwarded && _shouldSpawnPlayer()) {
      return PowerUpType.player;
    }

    final table = switch (activePowerUp) {
      PowerUpType.cattch => _withoutCatch,
      PowerUpType.extend => _withoutExtend,
      PowerUpType.laser => _withoutLaser,
      _ => _defaultTypes,
    };
    return table[_randomInt(table.length)];
  }

  bool _shouldSpawnBreak() {
    if (_capsulesLeftInBreakCycle == 0) {
      _capsulesLeftInBreakCycle = 33;
      _breakCountdown = _randomInt(32);
    }
    _capsulesLeftInBreakCycle -= 1;
    if (_breakCountdown == 0) {
      _breakCountdown = -1;
      return true;
    }
    if (_breakCountdown > 0) {
      _breakCountdown -= 1;
    }
    return false;
  }

  bool _shouldSpawnPlayer() {
    if (_playerLowCounter == 0) {
      _playerLowCounter = 50;
      _playerHighCounter = _randomInt(32);
    }
    _playerLowCounter -= 1;
    if (_playerHighCounter == 0) {
      _playerHighCounter = 255;
      return true;
    }
    _playerHighCounter -= 1;
    return false;
  }
}
