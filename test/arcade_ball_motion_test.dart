import 'dart:math';

import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/level_catalog.dart';
import 'package:arkanoid/physics/arcade_ball_motion.dart';
import 'package:arkanoid/round_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rounds 1-16 start at stage 12 and later rounds at stage 13', () {
    expect(Ball(rules: RoundRules(1)).speedStage, 12);
    expect(Ball(rules: RoundRules(16)).speedStage, 12);
    expect(Ball(rules: RoundRules(17)).speedStage, 13);
    expect(Ball(rules: RoundRules(32)).speedStage, 13);
  });

  test('speed advances with the original impact thresholds', () {
    final motion = ArcadeBallMotion(speedStage: 12);

    for (var impact = 0; impact < 8; impact++) {
      expect(motion.registerImpact(), isFalse);
    }
    expect(motion.speedStage, 12);
    expect(motion.registerImpact(), isTrue);
    expect(motion.speedStage, 13);
    expect(motion.speedProgress, 0);
  });

  test('advanced speed stages stay gradual and controllable', () {
    final speeds = <double>[];

    for (var stage = 12; stage <= 15; stage++) {
      final velocity = ArcadeBallMotion(speedStage: stage).velocity;
      speeds.add(sqrt(velocity.x * velocity.x + velocity.y * velocity.y));
    }

    final expectedSpeeds = [184.0, 196.0, 208.0, 220.0];
    for (var index = 0; index < speeds.length; index++) {
      expect(speeds[index], closeTo(expectedSpeeds[index], 0.000001));
    }
  });

  test('slow drops exactly one stage and clears its progress', () {
    final motion = ArcadeBallMotion(speedStage: 13);
    motion.registerImpact();

    expect(motion.slow(), isTrue);
    expect(motion.speedStage, 12);
    expect(motion.speedProgress, 0);
  });

  test('the six paddle zones select the original trajectories', () {
    final motion = ArcadeBallMotion(speedStage: 12);
    final trajectories = <int>[];

    for (final hit in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]) {
      motion.bounceFromPaddle(hit);
      trajectories.add(motion.trajectory);
      expect(motion.velocity.y, lessThan(0));
    }

    expect(trajectories, [7, 6, 5, 4, 3, 2]);
  });

  test('horizontal and vertical bounces preserve a discrete trajectory', () {
    final motion = ArcadeBallMotion(speedStage: 12);

    motion.bounceHorizontally();
    expect(motion.trajectory, 6);
    expect(motion.velocity.x, lessThan(0));
    expect(motion.velocity.y, lessThan(0));

    motion.bounceVertically();
    expect(motion.trajectory, -3);
    expect(motion.velocity.x, lessThan(0));
    expect(motion.velocity.y, greaterThan(0));
  });

  test('wall and gold counters change every active ball trajectory', () {
    final level = BaseLevel(levelCatalog.first);
    final first = Ball();
    final second = Ball();
    level.balls.addAll([first, second]);

    for (var bounce = 0; bounce < 40; bounce++) {
      level.onBallWallBounce();
    }
    expect(first.trajectory, 4);
    expect(second.trajectory, 4);

    final gold = Brick(BrickModel.gold, null);
    for (var hit = 0; hit < 20; hit++) {
      level.onBallBrickImpact(gold);
    }
    expect(first.trajectory, 3);
    expect(second.trajectory, 3);
  });
}
