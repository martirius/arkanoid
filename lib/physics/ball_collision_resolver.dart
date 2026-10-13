import 'dart:math';
import 'dart:ui';

enum BallCollisionAxis { horizontal, vertical }

enum _BallCollisionSide { left, right, top, bottom }

typedef BallCollisionCandidate<T> = ({T target, Rect bounds});

class BallCollisionResolution<T> {
  const BallCollisionResolution({
    required this.target,
    required this.ballBounds,
    required this.velocity,
  });

  final T target;
  final Rect ballBounds;
  final Offset velocity;
}

class BallCollisionResolver {
  static const _tolerance = 0.0001;

  static BallCollisionResolution<T>? resolve<T>({
    required Rect ballBounds,
    required Rect? previousBallBounds,
    required Offset velocity,
    required Iterable<BallCollisionCandidate<T>> candidates,
  }) {
    final evaluated = candidates
        .map(
          (candidate) => _EvaluatedCandidate(
            candidate,
            _collisionImpact(
              ballBounds,
              previousBallBounds,
              candidate.bounds,
              velocity,
            ),
          ),
        )
        .toList();
    if (evaluated.isEmpty) {
      return null;
    }

    evaluated.sort((first, second) {
      if ((first.impact.time - second.impact.time).abs() > _tolerance) {
        return first.impact.time.compareTo(second.impact.time);
      }
      if (first.impact.isAmbiguous != second.impact.isAmbiguous) {
        return first.impact.isAmbiguous ? 1 : -1;
      }
      if (first.impact.isAmbiguous) {
        return _separationDistance(ballBounds, first)
            .compareTo(_separationDistance(ballBounds, second));
      }
      return _contactsAfterBounce(ballBounds, first, evaluated)
          .compareTo(_contactsAfterBounce(ballBounds, second, evaluated));
    });

    final collision = evaluated.first;
    return BallCollisionResolution(
      target: collision.candidate.target,
      ballBounds: _resolvedBounds(
        ballBounds,
        collision.candidate.bounds,
        collision.impact.side,
      ),
      velocity: _reflectedVelocity(velocity, collision.impact.side),
    );
  }

  static BallCollisionAxis collisionAxis(Rect ball, Rect obstacle) {
    final horizontalPenetration = min(
      ball.right - obstacle.left,
      obstacle.right - ball.left,
    );
    final verticalPenetration = min(
      ball.bottom - obstacle.top,
      obstacle.bottom - ball.top,
    );
    return verticalPenetration <= horizontalPenetration
        ? BallCollisionAxis.vertical
        : BallCollisionAxis.horizontal;
  }

  static _CollisionImpact _collisionImpact(
    Rect ball,
    Rect? previousBall,
    Rect obstacle,
    Offset velocity,
  ) {
    if (previousBall == null) {
      return _CollisionImpact(
        0,
        _nearestSide(ball, obstacle, velocity),
        true,
      );
    }

    final horizontalMovement = ball.left - previousBall.left;
    final verticalMovement = ball.top - previousBall.top;
    final horizontalEntry = _axisEntryTime(
      previousBall.left,
      previousBall.right,
      obstacle.left,
      obstacle.right,
      horizontalMovement,
    );
    final verticalEntry = _axisEntryTime(
      previousBall.top,
      previousBall.bottom,
      obstacle.top,
      obstacle.bottom,
      verticalMovement,
    );
    final entryTime = max(horizontalEntry, verticalEntry);

    if (entryTime == double.negativeInfinity ||
        entryTime == double.infinity ||
        (horizontalEntry - verticalEntry).abs() <= _tolerance) {
      return _CollisionImpact(
        entryTime == double.negativeInfinity ? 0 : entryTime,
        _nearestSide(ball, obstacle, velocity),
        true,
      );
    }

    if (horizontalEntry > verticalEntry) {
      return _CollisionImpact(
        entryTime,
        horizontalMovement > 0
            ? _BallCollisionSide.left
            : _BallCollisionSide.right,
        false,
      );
    }
    return _CollisionImpact(
      entryTime,
      verticalMovement > 0 ? _BallCollisionSide.top : _BallCollisionSide.bottom,
      false,
    );
  }

  static double _axisEntryTime(
    double previousMin,
    double previousMax,
    double obstacleMin,
    double obstacleMax,
    double movement,
  ) {
    if (previousMax <= obstacleMin + _tolerance) {
      return movement > 0
          ? max(0, obstacleMin - previousMax) / movement
          : double.infinity;
    }
    if (previousMin >= obstacleMax - _tolerance) {
      return movement < 0
          ? max(0, previousMin - obstacleMax) / -movement
          : double.infinity;
    }
    return double.negativeInfinity;
  }

  static double _separationDistance<T>(
    Rect ball,
    _EvaluatedCandidate<T> candidate,
  ) {
    final resolved = _resolvedBounds(
      ball,
      candidate.candidate.bounds,
      candidate.impact.side,
    );
    return (resolved.left - ball.left).abs() + (resolved.top - ball.top).abs();
  }

  static int _contactsAfterBounce<T>(
    Rect ball,
    _EvaluatedCandidate<T> candidate,
    List<_EvaluatedCandidate<T>> candidates,
  ) {
    final resolved = _resolvedBounds(
      ball,
      candidate.candidate.bounds,
      candidate.impact.side,
    );
    return candidates
        .where(
          (other) =>
              !identical(other, candidate) &&
              resolved.overlaps(other.candidate.bounds),
        )
        .length;
  }

  static Rect _resolvedBounds(
    Rect ball,
    Rect obstacle,
    _BallCollisionSide side,
  ) {
    return switch (side) {
      _BallCollisionSide.top => Rect.fromLTWH(
          ball.left,
          obstacle.top - ball.height - 1,
          ball.width,
          ball.height,
        ),
      _BallCollisionSide.bottom => Rect.fromLTWH(
          ball.left,
          obstacle.bottom + 1,
          ball.width,
          ball.height,
        ),
      _BallCollisionSide.left => Rect.fromLTWH(
          obstacle.left - ball.width - 1,
          ball.top,
          ball.width,
          ball.height,
        ),
      _BallCollisionSide.right => Rect.fromLTWH(
          obstacle.right + 1,
          ball.top,
          ball.width,
          ball.height,
        ),
    };
  }

  static Offset _reflectedVelocity(
    Offset velocity,
    _BallCollisionSide side,
  ) {
    return switch (side) {
      _BallCollisionSide.top => Offset(velocity.dx, -velocity.dy.abs()),
      _BallCollisionSide.bottom => Offset(velocity.dx, velocity.dy.abs()),
      _BallCollisionSide.left => Offset(-velocity.dx.abs(), velocity.dy),
      _BallCollisionSide.right => Offset(velocity.dx.abs(), velocity.dy),
    };
  }

  static _BallCollisionSide _nearestSide(
    Rect ball,
    Rect obstacle,
    Offset velocity,
  ) {
    final axis = collisionAxis(ball, obstacle);
    if (axis == BallCollisionAxis.horizontal) {
      final centerDifference = ball.center.dx - obstacle.center.dx;
      if (centerDifference.abs() <= _tolerance) {
        return velocity.dx > 0
            ? _BallCollisionSide.left
            : _BallCollisionSide.right;
      }
      return centerDifference < 0
          ? _BallCollisionSide.left
          : _BallCollisionSide.right;
    }
    final centerDifference = ball.center.dy - obstacle.center.dy;
    if (centerDifference.abs() <= _tolerance) {
      return velocity.dy > 0
          ? _BallCollisionSide.top
          : _BallCollisionSide.bottom;
    }
    return centerDifference < 0
        ? _BallCollisionSide.top
        : _BallCollisionSide.bottom;
  }
}

class _CollisionImpact {
  const _CollisionImpact(this.time, this.side, this.isAmbiguous);

  final double time;
  final _BallCollisionSide side;
  final bool isAmbiguous;
}

class _EvaluatedCandidate<T> {
  const _EvaluatedCandidate(this.candidate, this.impact);

  final BallCollisionCandidate<T> candidate;
  final _CollisionImpact impact;
}
