import 'dart:ui' show Offset, Rect;

import 'package:arkanoid/components/projectile_target.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/main.dart';
import 'package:arkanoid/physics/arcade_ball_motion.dart';
import 'package:arkanoid/physics/ball_collision_resolver.dart';
import 'package:arkanoid/round_rules.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

class Ball extends PositionedEntity
    with CollisionCallbacks, HasGameReference<Arkanoid> {
  Ball({RoundRules? rules})
      : motion = ArcadeBallMotion(
          speedStage: (rules ?? RoundRules(1)).initialBallSpeedStage,
        ),
        super(
          size: Vector2(_ballWidth, _ballHeight),
          children: [RectangleHitbox(isSolid: true)],
          anchor: Anchor.topLeft,
        ) {
    final initialVelocity = motion.velocity;
    velocity = Vector2(initialVelocity.x, initialVelocity.y);
  }

  final ArcadeBallMotion motion;
  late Vector2 velocity;
  bool ballCanMove = false;
  final Set<PositionComponent> _collisionCandidates = {};
  final Vector2 _previousPosition = Vector2.zero();
  bool _hasPreviousPosition = false;

  static const _ballWidth = 5.0;
  static const _ballHeight = 4.0;

  int get speedStage => motion.speedStage;
  int get speedProgress => motion.speedProgress;
  int get trajectory => motion.trajectory;

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
        .addListener(_resolveProjectileCollision);
  }

  @override
  void onRemove() {
    game.collisionDetection.collisionsCompletedNotifier
        .removeListener(_resolveProjectileCollision);
    _collisionCandidates.clear();
    super.onRemove();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is ProjectileTarget) {
      _collisionCandidates.add(other);
    } else if (other is Starship && ballCanMove && velocity.y > 0) {
      final starship = other;
      final ballCenterX = x + size.x * scale.x / 2;
      final starshipWidth = starship.width * starship.scale.x;
      final normalizedHitPosition = (ballCenterX - starship.x) / starshipWidth;

      y = starship.y - size.y * scale.y - 1;
      motion.bounceFromPaddle(normalizedHitPosition);
      _applyMotionVelocity();
      _registerImpact();
      game.audio.play(GameSound.ballHitStarship);
    }
  }

  void _resolveProjectileCollision() {
    if (_collisionCandidates.isEmpty) {
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
      candidates: _collisionCandidates.map(
        (target) => (target: target, bounds: _bounds(target)),
      ),
    );
    _collisionCandidates.clear();
    if (resolution == null) {
      return;
    }

    final previousVelocity = velocity.clone();
    position.setValues(
      resolution.ballBounds.left,
      resolution.ballBounds.top,
    );
    velocity.setValues(
      resolution.velocity.dx,
      resolution.velocity.dy,
    );
    _syncTrajectoryAfterReflection(previousVelocity);

    final target = resolution.target;
    (target as ProjectileTarget).hitByBall();
    _registerImpact();
  }

  void _syncTrajectoryAfterReflection(Vector2 previousVelocity) {
    if (_directionChanged(previousVelocity.x, velocity.x)) {
      motion.bounceHorizontally();
    }
    if (_directionChanged(previousVelocity.y, velocity.y)) {
      motion.bounceVertically();
    }
  }

  static bool _directionChanged(double before, double after) =>
      before != 0 && after != 0 && before.sign != after.sign;

  void _registerImpact() {
    if (motion.registerImpact()) {
      _applyMotionVelocity();
    }
  }

  void _applyMotionVelocity() {
    final nextVelocity = motion.velocity;
    velocity.setValues(nextVelocity.x, nextVelocity.y);
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
      motion.bounceHorizontally();
      _registerImpact();
    } else if (x >= field.rightWall - size.x * scale.x && velocity.x > 0) {
      velocity.x = -velocity.x.abs();
      motion.bounceHorizontally();
      _registerImpact();
    }
    if (y <= field.topWall && velocity.y < 0) {
      velocity.y = velocity.y.abs();
      motion.bounceVertically();
      _registerImpact();
    }
    _previousPosition.setFrom(position);
    _hasPreviousPosition = true;
    x += velocity.x * dt;
    y += velocity.y * dt;
  }

  void launch() => ballCanMove = true;

  void slow() {
    motion.slow();
    _applyMotionVelocity();
  }

  void bounceFromObstacle(PositionComponent obstacle) {
    final deltaX = center.x - obstacle.center.x;
    final deltaY = center.y - obstacle.center.y;
    if (deltaX.abs() > deltaY.abs()) {
      motion.bounceHorizontally();
      x += deltaX < 0 ? -1 : 1;
    } else {
      motion.bounceVertically();
      y += deltaY < 0 ? -1 : 1;
    }
    _applyMotionVelocity();
  }
}
