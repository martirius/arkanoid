import 'dart:ui';

import 'package:arkanoid/physics/ball_collision_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns no collision when there are no candidates', () {
    final result = BallCollisionResolver.resolve<String>(
      ballBounds: const Rect.fromLTWH(0, 0, 5, 4),
      previousBallBounds: null,
      velocity: const Offset(1, 1),
      candidates: const [],
    );

    expect(result, isNull);
  });

  test('selects the earliest impact and reflects its vertical velocity', () {
    final result = BallCollisionResolver.resolve(
      ballBounds: const Rect.fromLTWH(15, 84, 5, 4),
      previousBallBounds: const Rect.fromLTWH(17, 87, 5, 4),
      velocity: const Offset(-240, -360),
      candidates: const [
        (target: 'left', bounds: Rect.fromLTWH(0, 78, 16, 8)),
        (target: 'right', bounds: Rect.fromLTWH(16, 78, 16, 8)),
      ],
    );

    expect(result?.target, 'right');
    expect(result?.ballBounds, const Rect.fromLTWH(15, 87, 5, 4));
    expect(result?.velocity, const Offset(-240, 360));
  });

  test('resolves the same bounce regardless of candidate order', () {
    const ball = Rect.fromLTWH(47.9999615, 29.9473006, 5, 4);
    const previousBall = Rect.fromLTWH(46.0636295, 29.265307, 5, 4);
    const velocity = Offset(232.35984, 81.83923);
    const candidates = [
      (target: 'topLeft', bounds: Rect.fromLTWH(32, 24, 16, 8)),
      (target: 'topRight', bounds: Rect.fromLTWH(48, 24, 16, 8)),
      (target: 'bottomLeft', bounds: Rect.fromLTWH(32, 32, 16, 8)),
      (target: 'bottomRight', bounds: Rect.fromLTWH(48, 32, 16, 8)),
    ];

    final normal = BallCollisionResolver.resolve(
      ballBounds: ball,
      previousBallBounds: previousBall,
      velocity: velocity,
      candidates: candidates,
    );
    final reversed = BallCollisionResolver.resolve(
      ballBounds: ball,
      previousBallBounds: previousBall,
      velocity: velocity,
      candidates: candidates.reversed,
    );

    expect(normal?.target, isNotNull);
    expect(reversed?.target, isNotNull);
    expect(reversed?.ballBounds, normal?.ballBounds);
    expect(reversed?.velocity, normal?.velocity);
  });
}
