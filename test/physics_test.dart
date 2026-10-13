import 'dart:ui';

import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/main.dart';
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
  _TestBrick() : super(BrickModel.grey, null);

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
      Ball.collisionAxis(
        const Rect.fromLTWH(15, 7, 5, 5),
        obstacle,
      ),
      BallCollisionAxis.vertical,
    );
    expect(
      Ball.collisionAxis(
        const Rect.fromLTWH(7, 12, 5, 5),
        obstacle,
      ),
      BallCollisionAxis.horizontal,
    );
  });

  test('ball only bounces when moving towards a field wall', () {
    final game = Arkanoid()..scaleFactor = 1;
    game.currentLevel.field = Field(FieldType.blue)
      ..position = Vector2(112, 0)
      ..scale = Vector2.all(1);
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

    ball.position = Vector2(8, 8);
    ball.velocity = Vector2(-130, -130);
    ball.update(1 / 120);

    expect(ball.velocity.x, 130);
    expect(ball.velocity.y, 130);
  });

  test('lateral entry between brick rows keeps a horizontal bounce', () {
    for (final verticalVelocity in [120.0, -120.0]) {
      final game = Arkanoid()..scaleFactor = 1;
      game.currentLevel.field = Field(FieldType.blue)
        ..position = Vector2(112, 0)
        ..scale = Vector2.all(1);
      final ball = Ball()
        ..game = game
        ..ballCanMove = true
        ..position = Vector2(11, verticalVelocity > 0 ? 83 : 85)
        ..velocity = Vector2(300, verticalVelocity);
      final brick = _TestBrick()..position = Vector2(16, 86);

      ball.update(1 / 120);
      final collisionY = ball.y;
      ball.onCollisionStart({Vector2.zero()}, brick);
      ball.onCollision({Vector2.zero()}, brick);

      expect(ball.x, 10);
      expect(ball.y, collisionY);
      expect(ball.velocity.x, -300);
      expect(ball.velocity.y, verticalVelocity);
    }
  });

  test('vertical entry between brick columns keeps a vertical bounce', () {
    final game = Arkanoid()..scaleFactor = 1;
    game.currentLevel.field = Field(FieldType.blue)
      ..position = Vector2(112, 0)
      ..scale = Vector2.all(1);
    final ball = Ball()
      ..game = game
      ..ballCanMove = true
      ..position = Vector2(14, 86)
      ..velocity = Vector2(120, -240);
    final brick = _TestBrick()..position = Vector2(16, 78);

    ball.update(1 / 120);
    final collisionX = ball.x;
    ball.onCollisionStart({Vector2.zero()}, brick);
    ball.onCollision({Vector2.zero()}, brick);

    expect(ball.x, collisionX);
    expect(ball.y, 87);
    expect(ball.velocity.x, 120);
    expect(ball.velocity.y, 240);
  });

  test('only one brick is hit during the same contact cluster', () {
    final ball = Ball()
      ..position = Vector2(14, 8)
      ..velocity = Vector2(0, 130);
    final firstBrick = _TestBrick()..position = Vector2(0, 10);
    final secondBrick = _TestBrick()..position = Vector2(16, 10);
    final intersectionPoints = {Vector2.zero()};

    ball.onCollisionStart(intersectionPoints, firstBrick);
    ball.onCollision(intersectionPoints, firstBrick);
    ball.onCollisionStart(intersectionPoints, secondBrick);
    ball.onCollision(intersectionPoints, secondBrick);

    expect(firstBrick.hits, 1);
    expect(secondBrick.hits, 0);

    ball.onCollisionEnd(firstBrick);
    ball.onCollision(intersectionPoints, secondBrick);
    expect(secondBrick.hits, 0);

    ball.onCollisionEnd(secondBrick);
    ball.position = Vector2(14, 8);
    ball.velocity = Vector2(0, 130);
    ball.onCollisionStart(intersectionPoints, secondBrick);
    ball.onCollision(intersectionPoints, secondBrick);

    expect(secondBrick.hits, 1);
  });
}
