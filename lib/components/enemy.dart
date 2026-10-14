import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/laser.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum EnemyType { konerd, pyradok, triSphere, opopo }

enum EnemyState { active, exploding }

class Enemy extends SpriteAnimationGroupComponent<EnemyState>
    with CollisionCallbacks {
  Enemy({
    required this.type,
    required this.playArea,
    required this.onDestroyed,
    required this.onRemoved,
  }) : super(
          size: Vector2.all(16),
          anchor: Anchor.center,
          priority: 15,
        );

  static const _spriteLayouts = {
    EnemyType.konerd: (y: 0.0, frames: 8, framesPerRow: 8),
    EnemyType.pyradok: (y: 16.0, frames: 11, framesPerRow: 6),
    EnemyType.triSphere: (y: 48.0, frames: 24, framesPerRow: 8),
    EnemyType.opopo: (y: 96.0, frames: 10, framesPerRow: 5),
  };
  static const _baseVelocities = {
    EnemyType.konerd: (x: 38.0, y: 24.0),
    EnemyType.pyradok: (x: -32.0, y: 27.0),
    EnemyType.triSphere: (x: 24.0, y: 32.0),
    EnemyType.opopo: (x: -20.0, y: 22.0),
  };

  final EnemyType type;
  final Rect Function() playArea;
  final void Function(Enemy) onDestroyed;
  final void Function(Enemy) onRemoved;
  final Vector2 _velocity = Vector2.zero();
  double _elapsed = 0;
  double _explosionElapsed = 0;
  bool _destroyed = false;

  @override
  Future<void> onLoad() async {
    final image = await Flame.images.load('aliens.png');
    final spriteLayout = _spriteLayouts[type]!;
    animations = {
      EnemyState.active: SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: spriteLayout.frames,
          amountPerRow: spriteLayout.framesPerRow,
          stepTime: 0.08,
          textureSize: Vector2.all(16),
          texturePosition: Vector2(0, spriteLayout.y),
        ),
      ),
      EnemyState.exploding: SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.06,
          loop: false,
          textureSize: Vector2.all(16),
          texturePosition: Vector2(0, 128),
        ),
      ),
    };
    final baseVelocity = _baseVelocities[type]!;
    _velocity.setValues(baseVelocity.x, baseVelocity.y);
    current = EnemyState.active;
    add(CircleHitbox(radius: 6, position: Vector2.all(2)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_destroyed) {
      _explosionElapsed += dt;
      if (_explosionElapsed >= 0.36) {
        removeFromParent();
      }
      return;
    }

    _elapsed += dt;
    final horizontalDrift = switch (type) {
      EnemyType.konerd => 0.0,
      EnemyType.pyradok => math.sin(_elapsed * 5) * 22,
      EnemyType.triSphere => math.sin(_elapsed * 3) * 30,
      EnemyType.opopo => math.sin(_elapsed * 2) * 12,
    };
    position.x += (_velocity.x + horizontalDrift) * dt;
    position.y += _velocity.y * dt;

    final area = playArea();
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    if (x - halfWidth <= area.left && _velocity.x < 0) {
      x = area.left + halfWidth;
      _velocity.x = _velocity.x.abs();
    } else if (x + halfWidth >= area.right && _velocity.x > 0) {
      x = area.right - halfWidth;
      _velocity.x = -_velocity.x.abs();
    }
    if (y - halfHeight <= area.top && _velocity.y < 0) {
      y = area.top + halfHeight;
      _velocity.y = _velocity.y.abs();
    } else if (y + halfHeight >= area.bottom) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_destroyed) {
      return;
    }
    if (other is Ball) {
      other.bounceFromObstacle(this);
      destroy();
    } else if (other is Laser) {
      other.removeLaserFromGame();
      destroy();
    } else if (other is Starship) {
      destroy();
    } else if (other is Brick) {
      _bounceFrom(other);
    }
  }

  void _bounceFrom(PositionComponent other) {
    final deltaX = x - other.center.x;
    final deltaY = y - other.center.y;
    if (deltaX.abs() > deltaY.abs()) {
      _velocity.x = deltaX.isNegative ? -_velocity.x.abs() : _velocity.x.abs();
    } else {
      _velocity.y = deltaY.isNegative ? -_velocity.y.abs() : _velocity.y.abs();
    }
  }

  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    _velocity.setZero();
    removeAll(children);
    current = EnemyState.exploding;
    animationTicker?.reset();
    onDestroyed(this);
  }

  @override
  void onRemove() {
    onRemoved(this);
    super.onRemove();
  }
}
