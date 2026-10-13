import 'dart:math';
import 'dart:ui' show Offset, Rect;

import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/main.dart';
import 'package:arkanoid/physics/ball_collision_resolver.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

class Ball extends PositionedEntity
    with CollisionCallbacks, HasGameReference<Arkanoid> {
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
    game.collisionDetection.collisionsCompletedNotifier
        .addListener(_resolveBrickCollision);
  }

  @override
  void onRemove() {
    game.collisionDetection.collisionsCompletedNotifier
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
      game.audio.play(GameSound.ballHitStarship);
    }
  }

  void _resolveBrickCollision() {
    if (_brickCollisionCandidates.isEmpty) {
      return;
    }

    final ballBounds = _bounds(this);
    final resolution = BallCollisionResolver.resolve(
      ballBounds: ballBounds,
      previousBallBounds: _hasPreviousPosition
          ? Rect.fromLTWH(
              _previousPosition.x,
              _previousPosition.y,
              ballBounds.width,
              ballBounds.height,
            )
          : null,
      velocity: Offset(velocity.x, velocity.y),
      candidates: _brickCollisionCandidates.map(
        (brick) => (target: brick, bounds: _bounds(brick)),
      ),
    );
    _brickCollisionCandidates.clear();
    if (resolution == null) {
      return;
    }

    final brick = resolution.target;
    brick.hit(true);
    _numberOfBrickHit += 1;
    position.setValues(
      resolution.ballBounds.left,
      resolution.ballBounds.top,
    );
    velocity.setValues(
      resolution.velocity.dx,
      resolution.velocity.dy,
    );
    if (_numberOfBrickHit < _maxBrickHitToIncreaseVelocity &&
        _numberOfBrickHit % _numberOfBricksHitToIncreaseVelocity == 0) {
      velocity *= 1.2;
    }
  }

  static Rect _bounds(PositionComponent component) {
    return Rect.fromLTWH(
      component.x,
      component.y,
      component.size.x * component.scale.x,
      component.size.y * component.scale.y,
    );
  }

  @override
  void update(double dt) {
    final field = game.currentLevel.field;
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
    final field = game.currentLevel.field;
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
