import 'dart:ui';

import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/brick.dart';
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
