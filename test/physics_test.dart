import 'dart:ui';

import 'package:arkanoid/components/ball.dart';
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
}
