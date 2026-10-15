import 'dart:math' as math;

import 'package:arkanoid/enemy_motion.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each arcade enemy follows its round-specific entry heading', () {
    const expectedLeft = {
      EnemyType.konerd: 0x0b,
      EnemyType.pyradok: 0x0e,
      EnemyType.triSphere: 0x0a,
      EnemyType.opopo: 0x0f,
    };
    const expectedRight = {
      EnemyType.konerd: 0x15,
      EnemyType.pyradok: 0x12,
      EnemyType.triSphere: 0x16,
      EnemyType.opopo: 0x11,
    };

    for (final type in EnemyType.values) {
      final left = ArcadeEnemyMotion(type: type, startsOnLeft: true);
      final right = ArcadeEnemyMotion(type: type, startsOnLeft: false);

      expect(left.direction, expectedLeft[type], reason: '${type.name} left');
      expect(left.velocity.x, greaterThan(0), reason: '${type.name} left');
      expect(right.direction, expectedRight[type],
          reason: '${type.name} right');
      expect(right.velocity.x, lessThan(0), reason: '${type.name} right');
    }
  });

  test('movement advances to the next ROM segment after its duration', () {
    final motion = ArcadeEnemyMotion(
      type: EnemyType.konerd,
      startsOnLeft: true,
    );

    motion.advance(47 / ArcadeEnemyMotion.framesPerSecond);
    expect(motion.direction, 0x0b);
    motion.advance(2 / ArcadeEnemyMotion.framesPerSecond);
    expect(motion.direction, 0x0a);
  });

  test('arcade obstacle reactions change heading and speed by enemy type', () {
    final konerd = ArcadeEnemyMotion(
      type: EnemyType.konerd,
      startsOnLeft: true,
      random: math.Random(1),
    );
    final triSphere = ArcadeEnemyMotion(
      type: EnemyType.triSphere,
      startsOnLeft: true,
      random: math.Random(1),
    );

    konerd.hitObstacle(bounceX: true);
    triSphere.hitObstacle(bounceX: true);

    expect(konerd.speedStage, 2);
    expect(triSphere.speedStage, 1);
    expect(konerd.velocity.x, lessThan(0));
    expect(triSphere.velocity.x, lessThan(0));
  });

  test('alien collision headings point away from one another', () {
    final first = ArcadeEnemyMotion(
      type: EnemyType.konerd,
      startsOnLeft: true,
    );
    final second = ArcadeEnemyMotion(
      type: EnemyType.konerd,
      startsOnLeft: false,
    );

    first.headAwayFrom(Vector2(-1, 0));
    second.headAwayFrom(Vector2(1, 0));

    expect(first.velocity.x, lessThan(0));
    expect(second.velocity.x, greaterThan(0));
  });
}
