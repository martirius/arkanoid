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
    if (collisionAxis(ballBounds, otherBounds) == BallCollisionAxis.vertical) {
      if (velocity.y > 0) {
        y = otherBounds.top - ballBounds.height - 1;
        velocity.y = -velocity.y.abs();
      } else {
        y = otherBounds.bottom + 1;
        velocity.y = velocity.y.abs();
      }
    } else if (velocity.x > 0) {
      x = otherBounds.left - ballBounds.width - 1;
      velocity.x = -velocity.x.abs();
    } else {
      x = otherBounds.right + 1;
      velocity.x = velocity.x.abs();
    }
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
    position.x = position.x.clamp(
      gameRef.currentLevel.field.leftWall,
      gameRef.currentLevel.field.rightWall,
    );
    position.y = position.y.clamp(
      gameRef.currentLevel.field.topWall,
      double.infinity,
    );
    if (y < gameRef.currentLevel.field.lowWall && ballCanMove) {
      calculateBallDirection(dt);
    }
  }

  void calculateBallDirection(double dt) {
    final field = gameRef.currentLevel.field;
    //calculate bouncing with Field borders
    if ((x <= field.leftWall || x >= field.rightWall - size.x * scale.x)) {
      velocity.x *= -1;
      //left wall or right wall
    } else if (y <= field.topWall) {
      //top wall
      velocity.y *= -1;
    }
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
