import 'dart:ui';

import 'package:arkanoid/components/projectile_target.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

class Doh extends SpriteAnimationComponent implements ProjectileTarget {
  Doh({
    required this.isPlaying,
    required this.target,
    required this.playArea,
    required this.onHit,
    required this.onProjectileHit,
    required this.onDefeatStarted,
    required this.onDefeated,
  }) : super(
          size: Vector2(64, 96),
          anchor: Anchor.center,
          priority: 20,
        );

  static const maxHits = 16;
  static const maxProjectiles = 3;
  static const scorePerHit = 1000;
  static const _projectileInterval = 1.5;
  static const _hitFlashDuration = 0.12;
  static const _deathDuration = 1.2;

  final bool Function() isPlaying;
  final Vector2 Function() target;
  final Rect Function() playArea;
  final void Function(bool playAudio) onHit;
  final void Function() onProjectileHit;
  final void Function() onDefeatStarted;
  final void Function() onDefeated;
  final Set<DohProjectile> _projectiles = {};
  late SpriteAnimation _activeAnimation;
  late List<Sprite> _hitSprites;
  late SpriteAnimation _deathAnimation;
  double _projectileElapsed = 0;
  double _hitFlashRemaining = 0;
  double _deathElapsed = 0;
  int _hits = 0;
  bool _defeated = false;
  bool _defeatReported = false;

  int get hits => _hits;
  bool get isDefeated => _defeated;
  int get activeProjectileCount => _projectiles.length;

  @override
  Future<void> onLoad() async {
    final image = await Flame.images.load('boss.png');
    _activeAnimation = SpriteAnimation.spriteList(
      [for (var column = 0; column < 4; column++) _sprite(image, column, 0)],
      stepTime: 0.16,
    );
    _hitSprites = [
      for (var row = 1; row <= 4; row++)
        for (var column = 0; column < 4; column++) _sprite(image, column, row),
    ];
    _deathAnimation = SpriteAnimation.spriteList(
      [
        for (var column = 0; column < 4; column++) _sprite(image, column, 5),
        for (var column = 0; column < 4; column++) _sprite(image, column, 6),
        for (var column = 0; column < 2; column++) _sprite(image, column, 7),
      ],
      stepTime: _deathDuration / 10,
      loop: false,
    );
    animation = _activeAnimation;
    add(
      RectangleHitbox(
        position: Vector2(6, 8),
        size: Vector2(52, 80),
        collisionType: CollisionType.passive,
        isSolid: true,
      ),
    );
  }

  Sprite _sprite(Image image, int column, int row) => Sprite(
        image,
        srcPosition: Vector2(column * 64, 144 + row * 96),
        srcSize: Vector2(64, 96),
      );

  void _hit(bool playAudio) {
    if (_defeated) {
      return;
    }

    _hits += 1;
    onHit(playAudio);
    if (_hits >= maxHits) {
      _defeated = true;
      clearProjectiles();
      if (isLoaded) {
        animation = _deathAnimation;
        animationTicker?.reset();
        removeAll(children);
      }
      onDefeatStarted();
      return;
    }

    if (isLoaded) {
      animation = SpriteAnimation.spriteList(
        [_hitSprites[_hits - 1]],
        stepTime: _hitFlashDuration,
        loop: false,
      );
      animationTicker?.reset();
      _hitFlashRemaining = _hitFlashDuration;
    }
  }

  @override
  void hitByBall() => _hit(true);

  @override
  void hitByLaser() => _hit(false);

  @override
  void update(double dt) {
    super.update(dt);
    if (_defeated) {
      _deathElapsed += dt;
      if (!_defeatReported && _deathElapsed >= _deathDuration) {
        _defeatReported = true;
        onDefeated();
      }
      return;
    }

    if (_hitFlashRemaining > 0) {
      _hitFlashRemaining -= dt;
      if (_hitFlashRemaining <= 0) {
        animation = _activeAnimation;
      }
    }
    if (!isPlaying() || parent == null) {
      return;
    }

    _projectileElapsed += dt;
    if (_projectileElapsed >= _projectileInterval &&
        _projectiles.length < maxProjectiles) {
      _projectileElapsed = 0;
      _spawnProjectile();
    }
  }

  void _spawnProjectile() {
    late final DohProjectile projectile;
    projectile = DohProjectile(
      origin: Vector2(x, y + 8),
      target: target(),
      playArea: playArea,
      onHit: () {
        if (isPlaying()) {
          onProjectileHit();
        }
      },
      onRemoved: () => _projectiles.remove(projectile),
    );
    _projectiles.add(projectile);
    parent?.add(projectile);
  }

  void clearProjectiles() {
    for (final projectile in _projectiles.toList()) {
      projectile.removeFromParent();
    }
    _projectiles.clear();
  }

  @override
  void onRemove() {
    clearProjectiles();
    super.onRemove();
  }
}

class DohProjectile extends RectangleComponent with CollisionCallbacks {
  DohProjectile({
    required Vector2 origin,
    required Vector2 target,
    required this.playArea,
    required this.onHit,
    required this.onRemoved,
  })  : _velocity = _velocityTowards(origin, target),
        super(
          position: origin,
          size: Vector2(8, 4),
          anchor: Anchor.center,
          priority: 25,
          paint: Paint()..color = const Color(0xfff2f2f2),
          children: [RectangleHitbox()],
        );

  static const _speed = 90.0;

  final Rect Function() playArea;
  final void Function() onHit;
  final void Function() onRemoved;
  final Vector2 _velocity;
  bool _spent = false;

  static Vector2 _velocityTowards(Vector2 origin, Vector2 target) {
    final direction = target - origin;
    if (direction.length2 == 0) {
      return Vector2(0, _speed);
    }
    return direction.normalized() * _speed;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    if (!playArea().inflate(8).contains(Offset(x, y))) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!_spent && other is Starship) {
      _spent = true;
      removeFromParent();
      onHit();
    }
  }

  @override
  void onRemove() {
    onRemoved();
    super.onRemove();
  }
}
