import 'dart:math';
import 'dart:ui' show Rect;

import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

enum BallCollisionAxis { horizontal, vertical }

enum _BallCollisionSide { left, right, top, bottom }

class Ball extends PositionedEntity
    with CollisionCallbacks, HasGameRef<Arkanoid> {
  Ball()
      : super(
            size: Vector2(_ballWidth, _ballHeight),
            children: [RectangleHitbox(isSolid: true)],
            anchor: Anchor.topLeft);

  Vector2 velocity = Vector2(130, -130);
  bool ballCanMove = false;
  int _numberOfBrickHit = 0;
  final Set<Brick> _brickCollisionCandidates = {};
  final Vector2 _previousPosition = Vector2.zero();
  bool _hasPreviousPosition = false;

  static const _ballWidth = 5.0;
  static const _ballHeight = 4.0;
  static const _numberOfBricksHitToIncreaseVelocity = 15;
  static const _maxBrickHitToIncreaseVelocity = 90;

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    await Flame.images.load('starship.png');
    add(SpriteComponent(sprite: extractSprite(0, 40, 5, 4, 'starship.png'))
      ..size = Vector2(_ballWidth, _ballHeight));
  }

  @override
  void onMount() {
    super.onMount();
    gameRef.collisionDetection.collisionsCompletedNotifier
        .addListener(_resolveBrickCollision);
  }

  @override
  void onRemove() {
    gameRef.collisionDetection.collisionsCompletedNotifier
        .removeListener(_resolveBrickCollision);
    _brickCollisionCandidates.clear();
    super.onRemove();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Brick) {
      _brickCollisionCandidates.add(other);
    } else if (other is Starship && ballCanMove && velocity.y > 0) {
      final starship = other;
      final ballSpeed = velocity.length;
      final ballCenterX = x + size.x * scale.x / 2;
      final starshipWidth = starship.width * starship.scale.x;
      final relativeIntersectX =
          (starship.x + starshipWidth - ballCenterX) / starshipWidth;
      var bounceAngle = relativeIntersectX.clamp(0.0, 1.0) * pi;
      bounceAngle = bounceAngle > pi / 2
          ? bounceAngle.clamp((pi / 2) + pi / 6, pi - pi / 6)
          : bounceAngle.clamp(pi / 6, (pi / 2) - pi / 6);

      y = starship.y - size.y * scale.y - 1;
      velocity.x = ballSpeed * cos(bounceAngle);
      velocity.y = ballSpeed * -sin(bounceAngle);
      gameRef.audio.play(GameSound.ballHitStarship);
    }
  }

  void _resolveBrickCollision() {
    if (_brickCollisionCandidates.isEmpty) {
      return;
    }

    final candidates = _brickCollisionCandidates.toList()
      ..sort((first, second) {
        final firstImpact = _collisionImpact(first);
        final secondImpact = _collisionImpact(second);
        if ((firstImpact.time - secondImpact.time).abs() > 0.0001) {
          return firstImpact.time.compareTo(secondImpact.time);
        }
        if (firstImpact.isAmbiguous != secondImpact.isAmbiguous) {
          return firstImpact.isAmbiguous ? 1 : -1;
        }
        if (firstImpact.isAmbiguous) {
          return _separationDistance(first)
              .compareTo(_separationDistance(second));
        }
        return _contactsAfterBounce(first)
            .compareTo(_contactsAfterBounce(second));
      });
    final brick = candidates.first;
    _brickCollisionCandidates.clear();
    brick.hit(true);
    _numberOfBrickHit += 1;
    if (_numberOfBrickHit < _maxBrickHitToIncreaseVelocity &&
        _numberOfBrickHit % _numberOfBricksHitToIncreaseVelocity == 0) {
      velocity *= 1.2;
    }
    _bounceOff(brick);
  }

  void _bounceOff(PositionComponent other) {
    final ballBounds = _scaledBounds(this);
    final otherBounds = _scaledBounds(other);
    switch (_collisionImpact(other).side) {
      case _BallCollisionSide.top:
        y = otherBounds.top - ballBounds.height - 1;
        velocity.y = -velocity.y.abs();
        break;
      case _BallCollisionSide.bottom:
        y = otherBounds.bottom + 1;
        velocity.y = velocity.y.abs();
        break;
      case _BallCollisionSide.left:
        x = otherBounds.left - ballBounds.width - 1;
        velocity.x = -velocity.x.abs();
        break;
      case _BallCollisionSide.right:
        x = otherBounds.right + 1;
        velocity.x = velocity.x.abs();
        break;
    }
  }

  ({double time, _BallCollisionSide side, bool isAmbiguous}) _collisionImpact(
    PositionComponent other,
  ) {
    final ball = _scaledBounds(this);
    final obstacle = _scaledBounds(other);
    if (!_hasPreviousPosition) {
      return (
        time: 0,
        side: _nearestSide(ball, obstacle),
        isAmbiguous: true,
      );
    }

    final previousBall = Rect.fromLTWH(
      _previousPosition.x,
      _previousPosition.y,
      ball.width,
      ball.height,
    );
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
        (horizontalEntry - verticalEntry).abs() <= 0.0001) {
      return (
        time: entryTime == double.negativeInfinity ? 0 : entryTime,
        side: _nearestSide(ball, obstacle),
        isAmbiguous: true,
      );
    }

    if (horizontalEntry > verticalEntry) {
      return (
        time: entryTime,
        side: horizontalMovement > 0
            ? _BallCollisionSide.left
            : _BallCollisionSide.right,
        isAmbiguous: false,
      );
    }
    return (
      time: entryTime,
      side: verticalMovement > 0
          ? _BallCollisionSide.top
          : _BallCollisionSide.bottom,
      isAmbiguous: false,
    );
  }

  static double _axisEntryTime(
    double previousMin,
    double previousMax,
    double obstacleMin,
    double obstacleMax,
    double movement,
  ) {
    const tolerance = 0.0001;
    if (previousMax <= obstacleMin + tolerance) {
      return movement > 0
          ? max(0, obstacleMin - previousMax) / movement
          : double.infinity;
    }
    if (previousMin >= obstacleMax - tolerance) {
      return movement < 0
          ? max(0, previousMin - obstacleMax) / -movement
          : double.infinity;
    }
    return double.negativeInfinity;
  }

  double _separationDistance(Brick brick) {
    final ball = _scaledBounds(this);
    final resolved = _resolvedBounds(brick);
    return (resolved.left - ball.left).abs() + (resolved.top - ball.top).abs();
  }

  int _contactsAfterBounce(Brick brick) {
    final resolvedBounds = _resolvedBounds(brick);
    return _brickCollisionCandidates
        .where((candidate) =>
            candidate != brick &&
            resolvedBounds.overlaps(_scaledBounds(candidate)))
        .length;
  }

  Rect _resolvedBounds(PositionComponent other) {
    final ball = _scaledBounds(this);
    final obstacle = _scaledBounds(other);
    return switch (_collisionImpact(other).side) {
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

  _BallCollisionSide _nearestSide(Rect ball, Rect obstacle) {
    final axis = collisionAxis(ball, obstacle);
    if (axis == BallCollisionAxis.horizontal) {
      final centerDifference = ball.center.dx - obstacle.center.dx;
      if (centerDifference.abs() <= 0.0001) {
        return velocity.x > 0
            ? _BallCollisionSide.left
            : _BallCollisionSide.right;
      }
      return centerDifference < 0
          ? _BallCollisionSide.left
          : _BallCollisionSide.right;
    }
    final centerDifference = ball.center.dy - obstacle.center.dy;
    if (centerDifference.abs() <= 0.0001) {
      return velocity.y > 0
          ? _BallCollisionSide.top
          : _BallCollisionSide.bottom;
    }
    return centerDifference < 0
        ? _BallCollisionSide.top
        : _BallCollisionSide.bottom;
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

  static Rect _scaledBounds(PositionComponent component) {
    return Rect.fromLTWH(
      component.x,
      component.y,
      component.size.x * component.scale.x,
      component.size.y * component.scale.y,
    );
  }

  @override
  void update(double dt) {
    final field = gameRef.currentLevel.field;
    position.x = position.x.clamp(
      field.leftWall,
      field.rightWall - size.x * scale.x,
    );
    position.y = position.y.clamp(
      field.topWall,
      double.infinity,
    );
    if (y < field.lowWall && ballCanMove) {
      calculateBallDirection(dt);
    }
  }

  void calculateBallDirection(double dt) {
    final field = gameRef.currentLevel.field;
    //calculate bouncing with Field borders
    if (x <= field.leftWall && velocity.x < 0) {
      velocity.x = velocity.x.abs();
    } else if (x >= field.rightWall - size.x * scale.x && velocity.x > 0) {
      velocity.x = -velocity.x.abs();
    }
    if (y <= field.topWall && velocity.y < 0) {
      velocity.y = velocity.y.abs();
    }
    _previousPosition.setFrom(position);
    _hasPreviousPosition = true;
    x += velocity.x * dt;
    y += velocity.y * dt;
  }

  void launch() => ballCanMove = true;

  void slow() {
    if (_numberOfBrickHit >= _numberOfBricksHitToIncreaseVelocity) {
      velocity /= ((_numberOfBrickHit > _maxBrickHitToIncreaseVelocity
                      ? _maxBrickHitToIncreaseVelocity
                      : _numberOfBrickHit) /
                  _numberOfBricksHitToIncreaseVelocity)
              .floor() *
          1.2;
      _numberOfBrickHit = 0;
    }
  }
}
