import 'dart:math';
import 'package:arkanoid/components/behaviours/action_behaviour.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/inputs/action_entity.dart';
import 'package:arkanoid/components/inputs/button_interactable.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/services.dart';

enum BallCollisionAxis { horizontal, vertical }

enum _BallCollisionSide { left, right, top, bottom }

class Ball extends PositionedEntity
    with CollisionCallbacks, HasGameRef<Arkanoid>, ActionEntity
    implements ButtonInteractable {
  Ball()
      : super(
            size: Vector2(_ballWidth, _ballHeight),
            behaviors: [ActionBehaviour(fireKey: LogicalKeyboardKey.space)],
            children: [RectangleHitbox(isSolid: true)],
            anchor: Anchor.topLeft);

  Vector2 velocity = Vector2(130, -130);
  bool ballCanMove = false;
  int _numberOfBrickHit = 0;
  Brick? _activeBrickCollision;
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
    scale *= gameRef.scaleFactor;
    add(SpriteComponent(sprite: extractSprite(0, 40, 5, 4, 'starship.png'))
      ..size = Vector2(_ballWidth, _ballHeight));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Brick) {
      if (_activeBrickCollision != null) {
        return;
      }
      _activeBrickCollision = other;
      other.hit(true);
      _numberOfBrickHit += 1;
      if (_numberOfBrickHit < _maxBrickHitToIncreaseVelocity &&
          _numberOfBrickHit % _numberOfBricksHitToIncreaseVelocity == 0) {
        velocity *= 1.2;
      }
      _bounceOff(other);
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

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Brick && !activeCollisions.any((item) => item is Brick)) {
      _activeBrickCollision = null;
    }
  }

  void _bounceOff(PositionComponent other) {
    final ballBounds = _scaledBounds(this);
    final otherBounds = _scaledBounds(other);
    switch (_collisionSide(ballBounds, otherBounds)) {
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

  _BallCollisionSide _collisionSide(Rect ball, Rect obstacle) {
    if (!_hasPreviousPosition) {
      return _sideFromAxis(collisionAxis(ball, obstacle));
    }

    final previousBall = Rect.fromLTWH(
      _previousPosition.x,
      _previousPosition.y,
      ball.width,
      ball.height,
    );
    const tolerance = 0.0001;
    final fromLeft =
        velocity.x > 0 && previousBall.right <= obstacle.left + tolerance;
    final fromRight =
        velocity.x < 0 && previousBall.left >= obstacle.right - tolerance;
    final fromAbove =
        velocity.y > 0 && previousBall.bottom <= obstacle.top + tolerance;
    final fromBelow =
        velocity.y < 0 && previousBall.top >= obstacle.bottom - tolerance;
    final horizontalApproach = fromLeft || fromRight;
    final verticalApproach = fromAbove || fromBelow;

    BallCollisionAxis axis;
    if (horizontalApproach && verticalApproach) {
      final horizontalDistance = fromLeft
          ? obstacle.left - previousBall.right
          : previousBall.left - obstacle.right;
      final verticalDistance = fromAbove
          ? obstacle.top - previousBall.bottom
          : previousBall.top - obstacle.bottom;
      final horizontalMovement = (ball.left - previousBall.left).abs();
      final verticalMovement = (ball.top - previousBall.top).abs();
      final horizontalEntry = horizontalDistance / horizontalMovement;
      final verticalEntry = verticalDistance / verticalMovement;
      axis = horizontalEntry > verticalEntry
          ? BallCollisionAxis.horizontal
          : BallCollisionAxis.vertical;
    } else if (horizontalApproach) {
      axis = BallCollisionAxis.horizontal;
    } else if (verticalApproach) {
      axis = BallCollisionAxis.vertical;
    } else {
      axis = collisionAxis(ball, obstacle);
    }

    if (axis == BallCollisionAxis.horizontal) {
      return fromLeft || (!fromRight && velocity.x > 0)
          ? _BallCollisionSide.left
          : _BallCollisionSide.right;
    }
    return fromAbove || (!fromBelow && velocity.y > 0)
        ? _BallCollisionSide.top
        : _BallCollisionSide.bottom;
  }

  _BallCollisionSide _sideFromAxis(BallCollisionAxis axis) {
    if (axis == BallCollisionAxis.horizontal) {
      return velocity.x > 0
          ? _BallCollisionSide.left
          : _BallCollisionSide.right;
    }
    return velocity.y > 0 ? _BallCollisionSide.top : _BallCollisionSide.bottom;
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
    x += velocity.x * dt * scale.x;
    y += velocity.y * dt * scale.y;
  }

  @override
  void onButtonPressed() {
    ballCanMove = true;
  }

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

  @override
  void onActionPressed() {
    onButtonPressed();
  }
}
