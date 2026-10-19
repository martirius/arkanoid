import 'dart:math' as math;

import 'package:arkanoid/enemy_motion.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each arcade enemy exits its gate vertically before free flight', () {
    for (final type in EnemyType.values) {
      final motion = ArcadeEnemyMotion(
        type: type,
        random: math.Random(type.index),
      );

      expect(motion.phase, EnemyMotionPhase.exiting, reason: type.name);
      expect(motion.direction, 0x10, reason: type.name);
      expect(motion.velocity.x.abs(), lessThan(0.0001), reason: type.name);
      expect(motion.velocity.y, greaterThan(0), reason: type.name);

      motion.finishGateExit();
      expect(motion.phase, EnemyMotionPhase.flying, reason: type.name);
    }
  });

  test('ROM movement pattern starts only when explicitly requested', () {
    final motion = ArcadeEnemyMotion(
      type: EnemyType.konerd,
      random: math.Random(1),
    );

    motion.finishGateExit();
    final freeFlightDirection = motion.direction;
    motion.advance(47 / ArcadeEnemyMotion.framesPerSecond);
    expect(motion.phase, EnemyMotionPhase.flying);
    expect(motion.direction, freeFlightDirection);

    motion.startObstaclePattern(onLeftSide: true);
    expect(motion.phase, EnemyMotionPhase.followingPattern);
    expect(motion.direction, 0x0b);
    motion.advance(25 / ArcadeEnemyMotion.framesPerSecond);
    expect(motion.direction, 0x0a);
  });

  test('starting an obstacle pattern changes speed only once by enemy type',
      () {
    final konerd = ArcadeEnemyMotion(
      type: EnemyType.konerd,
      random: math.Random(1),
    );
    final triSphere = ArcadeEnemyMotion(
      type: EnemyType.triSphere,
      random: math.Random(1),
    );

    konerd
      ..finishGateExit()
      ..startObstaclePattern(onLeftSide: true)
      ..startObstaclePattern(onLeftSide: true);
    triSphere
      ..finishGateExit()
      ..startObstaclePattern(onLeftSide: true);

    expect(konerd.speedStage, 2);
    expect(triSphere.speedStage, 1);
  });

  test('alien collision headings point away from one another', () {
    final first = ArcadeEnemyMotion(
      type: EnemyType.konerd,
      random: math.Random(1),
    );
    final second = ArcadeEnemyMotion(
      type: EnemyType.konerd,
      random: math.Random(2),
    );

    first.headAwayFrom(Vector2(-1, 0));
    second.headAwayFrom(Vector2(1, 0));

    expect(first.velocity.x, lessThan(0));
    expect(second.velocity.x, greaterThan(0));
  });

  test('a patterned enemy turns back into the field at either side', () {
    final motion = ArcadeEnemyMotion(
      type: EnemyType.triSphere,
      random: math.Random(1),
    )
      ..finishGateExit()
      ..startObstaclePattern(onLeftSide: true);

    expect(motion.velocity.x, greaterThan(0));

    motion.turnFromHorizontalBoundary(onLeftSide: false);
    expect(motion.velocity.x, lessThan(0));

    motion.turnFromHorizontalBoundary(onLeftSide: true);
    expect(motion.velocity.x, greaterThan(0));
  });

  test('the first patterned brick collision keeps the reflected heading', () {
    final motion = ArcadeEnemyMotion(
      type: EnemyType.triSphere,
      random: math.Random(1),
    )
      ..finishGateExit()
      ..startObstaclePattern(onLeftSide: true);
    final verticalDirectionBeforeCollision = motion.velocity.y.sign;

    motion.reflectFromObstacle(bounceX: false);

    expect(motion.velocity.y.sign, -verticalDirectionBeforeCollision);
  });
}
