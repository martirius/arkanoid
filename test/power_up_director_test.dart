import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/power_up_director.dart';
import 'package:flutter_test/flutter_test.dart';

class _SequenceRandom {
  _SequenceRandom(this.values);

  final List<int> values;
  int _index = 0;

  int nextInt(int max) => values[_index++] % max;
}

PowerUpType? _select(
  PowerUpDirector director, {
  PowerUpType? activePowerUp,
  bool hasFallingCapsule = false,
  bool hasMultipleBalls = false,
  bool portalOpen = false,
  int breakableBricksRemaining = 10,
  bool playerAlreadyAwarded = false,
}) =>
    director.select(
      activePowerUp: activePowerUp,
      hasFallingCapsule: hasFallingCapsule,
      hasMultipleBalls: hasMultipleBalls,
      portalOpen: portalOpen,
      breakableBricksRemaining: breakableBricksRemaining,
      playerAlreadyAwarded: playerAlreadyAwarded,
    );

void main() {
  test('drop blockers prevent capsule selection', () {
    final director = PowerUpDirector(randomInt: (_) => 0);

    expect(_select(director, hasFallingCapsule: true), isNull);
    expect(_select(director, hasMultipleBalls: true), isNull);
    expect(_select(director, portalOpen: true), isNull);
    expect(_select(director, breakableBricksRemaining: 3), isNull);
  });

  test('an eligible brick may not release a capsule', () {
    final director = PowerUpDirector(randomInt: (_) => 0);

    expect(_select(director), isNull);
  });

  test('the active persistent power-up is excluded from weighted selection',
      () {
    final random = _SequenceRandom([1, 31, 31, 1]);
    final director = PowerUpDirector(randomInt: random.nextInt);

    expect(
      _select(director, activePowerUp: PowerUpType.cattch),
      PowerUpType.extend,
    );
  });

  test('break uses one stateful position in each 33-capsule cycle', () {
    final random = _SequenceRandom([1, 1, 31, 0, 1]);
    final director = PowerUpDirector(randomInt: random.nextInt);

    expect(_select(director), PowerUpType.slow);
    expect(_select(director), PowerUpType.break_);
  });

  test('player is excluded after it has already been awarded', () {
    final random = _SequenceRandom([1, 31, 0]);
    final director = PowerUpDirector(randomInt: random.nextInt);

    expect(
      _select(director, playerAlreadyAwarded: true),
      PowerUpType.slow,
    );
  });
}
