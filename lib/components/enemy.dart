import 'dart:ui' show Image, Rect;

import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/laser.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/enemy_motion.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

export 'package:arkanoid/enemy_motion.dart' show EnemyType;

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

  static const arcadeFramesPerSecond = 60.0;
  static const _collisionRadius = 6.0;
  static const _gateExitDistance = 8.0;
  static const _brickNavigationTopOffset = 32.0;
  static const _spriteLayouts = {
    EnemyType.konerd: (y: 0.0, framesPerRow: 8),
    EnemyType.pyradok: (y: 16.0, framesPerRow: 6),
    EnemyType.triSphere: (y: 48.0, framesPerRow: 8),
    EnemyType.opopo: (y: 96.0, framesPerRow: 5),
  };
  static const _activeFrameIndexes = {
    EnemyType.konerd: [0, 1, 2, 3, 4, 5, 6, 7],
    EnemyType.pyradok: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 5],
    EnemyType.triSphere: [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
    ],
    EnemyType.opopo: [
      0,
      1,
      2,
      3,
      4,
      5,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      8,
      7,
      6,
      5,
    ],
  };
  static const _activeFrameTicks = {
    EnemyType.konerd: [7, 7, 7, 7, 7, 7, 7, 7],
    EnemyType.pyradok: [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10],
    EnemyType.triSphere: [
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
      5,
    ],
    EnemyType.opopo: [
      10,
      10,
      10,
      10,
      10,
      10,
      10,
      10,
      10,
      10,
      10,
      10,
      5,
      5,
      5,
      10,
      5,
      5,
      5,
      10,
    ],
  };
  static const _explosionFrameIndexes = [0, 1, 2, 3, 0, 4, 5];
  static const _explosionFrameTicks = 5;
  static const _explosionDuration =
      7 * _explosionFrameTicks / arcadeFramesPerSecond;
  final EnemyType type;
  final Rect Function() playArea;
  final void Function(Enemy) onDestroyed;
  final void Function(Enemy) onRemoved;
  late final ArcadeEnemyMotion _motion;
  late final double _gateExitY;
  final Set<Brick> _brickContacts = {};
  final Set<Brick> _resolvedBrickContacts = {};
  double _explosionElapsed = 0;
  bool _handledBrickCollisionThisFrame = false;
  bool _destroyed = false;

  @override
  Future<void> onLoad() async {
    final image = await Flame.images.load('aliens.png');
    final spriteLayout = _spriteLayouts[type]!;
    final activeIndexes = _activeFrameIndexes[type]!;
    final activeTicks = _activeFrameTicks[type]!;
    animations = {
      EnemyState.active: SpriteAnimation.variableSpriteList(
        [
          for (final index in activeIndexes)
            _spriteAt(image, spriteLayout, index),
        ],
        stepTimes: [
          for (final ticks in activeTicks) ticks / arcadeFramesPerSecond,
        ],
      ),
      EnemyState.exploding: SpriteAnimation.spriteList(
        [
          for (final index in _explosionFrameIndexes)
            Sprite(
              image,
              srcPosition: Vector2(index * 16, 128),
              srcSize: Vector2.all(16),
            ),
        ],
        stepTime: _explosionFrameTicks / arcadeFramesPerSecond,
        loop: false,
      ),
    };
    _motion = ArcadeEnemyMotion(
      type: type,
    );
    _gateExitY = y + _gateExitDistance;
    current = EnemyState.active;
    add(CircleHitbox(radius: _collisionRadius, position: Vector2.all(2)));
  }

  static Sprite _spriteAt(
    Image image,
    ({double y, int framesPerRow}) layout,
    int index,
  ) {
    return Sprite(
      image,
      srcPosition: Vector2(
        (index % layout.framesPerRow) * 16,
        layout.y + (index ~/ layout.framesPerRow) * 16,
      ),
      srcSize: Vector2.all(16),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _handledBrickCollisionThisFrame = false;
    if (_destroyed) {
      _explosionElapsed += dt;
      if (_explosionElapsed >= _explosionDuration) {
        removeFromParent();
      }
      return;
    }

    position.add(_motion.advance(dt));
    if (_motion.phase == EnemyMotionPhase.exiting && y >= _gateExitY) {
      y = _gateExitY;
      _motion.finishGateExit();
    }

    final area = playArea();
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    if (x - halfWidth <= area.left && _motion.velocity.x < 0) {
      x = area.left + halfWidth;
      _motion.reflectX();
    } else if (x + halfWidth >= area.right && _motion.velocity.x > 0) {
      x = area.right - halfWidth;
      _motion.reflectX();
    }
    if (y - halfHeight <= area.top && _motion.velocity.y < 0) {
      y = area.top + halfHeight;
      _motion.reflectY();
    } else if (y + halfHeight >= area.bottom) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_destroyed) {
      return;
    }
    if (other is Enemy) {
      _separateFrom(other);
    } else if (other is Brick) {
      _brickContacts.add(other);
      _handleBrickContact(other);
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
      _brickContacts.add(other);
      _handleBrickContact(other);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Brick) {
      _brickContacts.remove(other);
      _resolvedBrickContacts.remove(other);
    }
    super.onCollisionEnd(other);
  }

  void _handleBrickContact(Brick brick) {
    final area = playArea();
    if (_motion.phase == EnemyMotionPhase.exiting ||
        y < area.top + _brickNavigationTopOffset ||
        _resolvedBrickContacts.contains(brick)) {
      return;
    }
    if (_handledBrickCollisionThisFrame) {
      _resolvedBrickContacts.add(brick);
      return;
    }
    _handledBrickCollisionThisFrame = true;
    _resolvedBrickContacts.addAll(_brickContacts);
    _bounceFrom(brick);
  }

  void _bounceFrom(PositionComponent other) {
    final deltaX = x - other.center.x;
    final deltaY = y - other.center.y;
    final overlapX = _collisionRadius + other.width / 2 - deltaX.abs();
    final overlapY = _collisionRadius + other.height / 2 - deltaY.abs();
    final bounceX = overlapX < overlapY;
    if (bounceX && overlapX > 0) {
      final side = deltaX == 0 ? -_motion.velocity.x.sign : deltaX.sign;
      x += overlapX * (side == 0 ? 1 : side);
    } else if (!bounceX && overlapY > 0) {
      final side = deltaY == 0 ? -_motion.velocity.y.sign : deltaY.sign;
      y += overlapY * (side == 0 ? 1 : side);
    }

    if (_motion.phase == EnemyMotionPhase.flying) {
      _motion.startObstaclePattern(
        onLeftSide: x < playArea().center.dx,
      );
    } else {
      _motion.reflectFromObstacle(bounceX: bounceX);
    }
  }

  void _separateFrom(Enemy other) {
    if (other._destroyed || identityHashCode(this) > identityHashCode(other)) {
      return;
    }
    var normal = position - other.position;
    var distance = normal.length;
    if (distance == 0) {
      normal = Vector2(1, 0);
    } else {
      normal.scale(1 / distance);
    }
    const minimumDistance = 12.0;
    final overlap = minimumDistance - distance;
    if (overlap <= 0) {
      return;
    }
    final correction = normal * (overlap / 2);
    position.add(correction);
    other.position.sub(correction);
    if (_motion.phase == EnemyMotionPhase.exiting ||
        other._motion.phase == EnemyMotionPhase.exiting) {
      return;
    }
    _motion.headAwayFrom(normal);
    other._motion.headAwayFrom(-normal);
  }

  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
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
