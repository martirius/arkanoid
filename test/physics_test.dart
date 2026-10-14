import 'dart:ui';

import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/main.dart';
import 'package:arkanoid/physics/ball_collision_resolver.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

class _UpdateCounter extends Component {
  int updates = 0;
  double elapsed = 0;

  @override
  void update(double dt) {
    updates += 1;
    elapsed += dt;
  }
}

class _TestBrick extends Brick {
  _TestBrick() : super(BrickModel.grey);

  int hits = 0;

  @override
  void hit(bool playAudio) {
    hits += 1;
  }
}

void main() {
  test('long frames are split into bounded physics steps', () {
    expect(Arkanoid.physicsStepsFor(1 / 120), 1);
    expect(Arkanoid.physicsStepsFor(1 / 60), 2);
    expect(Arkanoid.physicsStepsFor(1 / 30), 4);
    expect(Arkanoid.physicsStepsFor(1), 8);
  });

  test('physics steps update the component tree without changing elapsed time',
      () {
    final game = Arkanoid();
    final counter = _UpdateCounter();
    game.add(counter);

    game.update(1 / 60);

    expect(counter.updates, 2);
    expect(counter.elapsed, closeTo(1 / 60, 0.000001));
  });

  test('collision axis follows the shallowest penetration', () {
    const obstacle = Rect.fromLTWH(10, 10, 20, 10);

    expect(
      BallCollisionResolver.collisionAxis(
        const Rect.fromLTWH(15, 7, 5, 5),
        obstacle,
      ),
      BallCollisionAxis.vertical,
    );
    expect(
      BallCollisionResolver.collisionAxis(
        const Rect.fromLTWH(7, 12, 5, 5),
        obstacle,
      ),
      BallCollisionAxis.horizontal,
    );
  });

  test('ball only bounces when moving towards a field wall', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final ball = Ball()
      ..game = game
      ..ballCanMove = true
      ..position = Vector2(216, 100)
      ..velocity = Vector2(-130, 0);

    ball.update(1 / 120);

    expect(ball.velocity.x, -130);
    expect(ball.x, lessThan(211));

    ball.position = Vector2(211, 100);
    ball.velocity = Vector2(130, 0);
    ball.update(1 / 120);

    expect(ball.velocity.x, -130);
    expect(ball.x, lessThan(211));
    expect(ball.speedProgress, 1);

    ball.position = Vector2(8, 8);
    ball.velocity = Vector2(-130, -130);
    ball.update(1 / 120);

    expect(ball.velocity.x, 130);
    expect(ball.velocity.y, 130);
    expect(ball.speedProgress, 3);
  });

  test('lateral entry between brick rows keeps a horizontal bounce', () {
    for (final verticalVelocity in [120.0, -120.0]) {
      final game = Arkanoid();
      game.currentLevel.field = Field(FieldType.blue)
        ..position = Vector2(112, 0);
      final ball = Ball()
        ..game = game
        ..ballCanMove = true
        ..position = Vector2(11, verticalVelocity > 0 ? 83 : 85)
        ..velocity = Vector2(300, verticalVelocity);
      final brick = _TestBrick()..position = Vector2(16, 86);
      ball.onMount();

      ball.update(1 / 120);
      final collisionY = ball.y;
      ball.onCollisionStart({Vector2.zero()}, brick);
      ball.onCollision({Vector2.zero()}, brick);
      game.collisionDetection.run();

      expect(ball.x, 10);
      expect(ball.y, collisionY);
      expect(ball.velocity.x, -300);
      expect(ball.velocity.y, verticalVelocity);
      expect(ball.speedProgress, 1);
    }
  });

  test('vertical entry between brick columns keeps a vertical bounce', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final ball = Ball()
      ..game = game
      ..ballCanMove = true
      ..position = Vector2(14, 86)
      ..velocity = Vector2(120, -240);
    final brick = _TestBrick()..position = Vector2(16, 78);
    ball.onMount();

    ball.update(1 / 120);
    final collisionX = ball.x;
    ball.onCollisionStart({Vector2.zero()}, brick);
    ball.onCollision({Vector2.zero()}, brick);
    game.collisionDetection.run();

    expect(ball.x, collisionX);
    expect(ball.y, 87);
    expect(ball.velocity.x, 120);
    expect(ball.velocity.y, 240);
  });

  test('earliest brick impact wins regardless of callback order', () {
    final scenarios = [
      (y: 87.0, vx: -240.0, vy: -360.0, expectedX: 15.0),
      (y: 88.0, vx: -180.0, vy: -360.0, expectedX: 15.5),
    ];
    for (final scenario in scenarios) {
      for (final reverseOrder in [false, true]) {
        final game = Arkanoid();
        game.currentLevel.field = Field(FieldType.blue)
          ..position = Vector2(112, 0);
        final ball = Ball()
          ..game = game
          ..ballCanMove = true
          ..position = Vector2(17, scenario.y)
          ..velocity = Vector2(scenario.vx, scenario.vy);
        final leftBrick = _TestBrick()..position = Vector2(0, 78);
        final rightBrick = _TestBrick()..position = Vector2(16, 78);
        final bricks =
            reverseOrder ? [rightBrick, leftBrick] : [leftBrick, rightBrick];
        ball.onMount();

        ball.update(1 / 120);
        for (final brick in bricks) {
          ball.onCollisionStart({Vector2.zero()}, brick);
          ball.onCollision({Vector2.zero()}, brick);
        }
        expect(leftBrick.hits, 0);
        expect(rightBrick.hits, 0);

        game.collisionDetection.run();

        expect(leftBrick.hits, 0);
        expect(rightBrick.hits, 1);
        expect(ball.x, scenario.expectedX);
        expect(ball.y, 87);
        expect(ball.velocity.x, scenario.vx);
        expect(ball.velocity.y, 360);
      }
    }
  });

  test('brick seam collision uses the nearest separation', () {
    Vector2 resolveCollision({required bool reverseOrder}) {
      final game = Arkanoid();
      game.currentLevel.field = Field(FieldType.blue)
        ..position = Vector2(112, 0);
      final ball = Ball()
        ..game = game
        ..ballCanMove = true
        ..position = Vector2(46.0636295, 29.265307)
        ..velocity = Vector2(232.35984, 81.83923);
      final bricks = [
        _TestBrick()..position = Vector2(32, 24),
        _TestBrick()..position = Vector2(48, 24),
        _TestBrick()..position = Vector2(32, 32),
        _TestBrick()..position = Vector2(48, 32),
      ];
      final collisionOrder = reverseOrder ? bricks.reversed : bricks;
      ball.onMount();

      ball.update(1 / 120);
      final collisionPosition = ball.position.clone();
      for (final brick in collisionOrder) {
        ball.onCollisionStart({Vector2.zero()}, brick);
        ball.onCollision({Vector2.zero()}, brick);
      }
      game.collisionDetection.run();

      expect(bricks.fold(0, (hits, brick) => hits + brick.hits), 1);
      expect(ball.position.distanceTo(collisionPosition), lessThan(6));
      return ball.position.clone();
    }

    final normalPosition = resolveCollision(reverseOrder: false);
    final reversedPosition = resolveCollision(reverseOrder: true);

    expect(reversedPosition.x, closeTo(normalPosition.x, 0.0001));
    expect(reversedPosition.y, closeTo(normalPosition.y, 0.0001));
  });

  test('adjacent brick is resolved on the next high-speed physics step', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final ball = Ball()
      ..game = game
      ..ballCanMove = true
      ..position = Vector2(10.95, 66.0941667)
      ..velocity = Vector2(396, 228.7);
    final leftBrick = _TestBrick()..position = Vector2(0, 70);
    final rightBrick = _TestBrick()..position = Vector2(16, 70);
    final intersectionPoints = {Vector2.zero()};
    ball.onMount();

    ball.update(1 / 120);
    for (final brick in [leftBrick, rightBrick]) {
      ball.onCollisionStart(intersectionPoints, brick);
      ball.onCollision(intersectionPoints, brick);
    }
    game.collisionDetection.run();

    expect(leftBrick.hits + rightBrick.hits, 1);
    expect(ball.x, closeTo(17, 0.0001));
    expect(ball.y, closeTo(68, 0.0001));

    ball.update(1 / 120);
    ball.onCollision(intersectionPoints, rightBrick);
    game.collisionDetection.run();

    expect(rightBrick.hits, 1);
    expect(ball.y, closeTo(65, 0.0001));
    expect(ball.velocity.y, lessThan(0));
  });

  test('only one brick is hit during each collision step', () {
    final game = Arkanoid();
    final ball = Ball()
      ..game = game
      ..position = Vector2(14, 8)
      ..velocity = Vector2(0, 130);
    final firstBrick = _TestBrick()..position = Vector2(0, 10);
    final secondBrick = _TestBrick()..position = Vector2(16, 10);
    final intersectionPoints = {Vector2.zero()};
    ball.onMount();

    ball.onCollisionStart(intersectionPoints, firstBrick);
    ball.onCollision(intersectionPoints, firstBrick);
    ball.onCollisionStart(intersectionPoints, secondBrick);
    ball.onCollision(intersectionPoints, secondBrick);
    game.collisionDetection.run();

    expect(firstBrick.hits, 1);
    expect(secondBrick.hits, 0);

    ball.onCollision(intersectionPoints, secondBrick);
    game.collisionDetection.run();
    expect(secondBrick.hits, 1);
  });
}
