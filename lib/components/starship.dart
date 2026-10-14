import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/laser.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

enum StarshipState { still, movingLeft, movingRight, escaping }

enum StarshipAnimation {
  normal,
  appearing,
  extended,
  laser,
  laserTransforming,
  disappearing
}

class Starship extends PositionedEntity
    with CollisionCallbacks, HasGameReference<Arkanoid> {
  Starship({
    required void Function(PowerUpType) onPowerUp,
    required void Function() onEscape,
  })  : _onPowerUp = onPowerUp,
        _onEscape = onEscape,
        super(
          size: Vector2(starshipWidth, starshipHeight),
          anchor: Anchor.topLeft,
          children: [RectangleHitbox(isSolid: true)],
          priority: 30,
        );

  StarshipState state = StarshipState.still;
  final StarshipAnimationComponent _starshipAnimationComponent =
      StarshipAnimationComponent(starshipWidth, starshipHeight);

  static const double starshipSpeed = 250;
  static const double _escapeSpeed = 30;
  static const double _catchDuration = 4;
  static const int _maxActiveLaserVolleys = 3;

  static const double starshipWidth = 32;
  static const double starshipHeight = 8;
  PowerUpType? powerUp;
  final void Function(PowerUpType) _onPowerUp;
  final void Function() _onEscape;
  bool _isDisappearing = false;
  final Map<Ball, double> _caughtBalls = {};
  bool _canEscape = false;
  bool _isEscaping = false;
  int _activeLaserVolleys = 0;
  int movementDirection = 0;

  @override
  Future<void>? onLoad() async {
    await Flame.images.load('starship.png');
    await add(_starshipAnimationComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isDisappearing) {
      final previousX = x;
      if (_isEscaping || state == StarshipState.escaping) {
        _isEscaping = true;
        state = StarshipState.escaping;
      } else {
        state = movementDirection < 0
            ? StarshipState.movingLeft
            : movementDirection > 0
                ? StarshipState.movingRight
                : StarshipState.still;
      }
      switch (state) {
        case StarshipState.movingLeft:
          x -= starshipSpeed * dt;
          break;
        case StarshipState.movingRight:
          x += starshipSpeed * dt;
          break;
        case StarshipState.escaping:
          _isEscaping = true;
          x += _escapeSpeed * dt;
          break;
        default:
          break;
      }

      if (state != StarshipState.escaping) {
        position.x = position.x.clamp(
          game.currentLevel.field.leftWall,
          game.currentLevel.field.rightWall - width * scale.x,
        );
        final movement = x - previousX;
        for (final ball in _caughtBalls.keys) {
          ball.x += movement;
        }
      }
    }
    _updateCaughtBalls(dt);
  }

  void setMovementDirection(int direction) => movementDirection = direction;

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (!_isDisappearing && state != StarshipState.escaping) {
      if (other is Field) {
        if (state == StarshipState.movingRight && _canEscape) {
          state = StarshipState.escaping;
          _onEscape();
        }
      } else if (other is PowerUp) {
        other.removeFromParent();
        _applyPowerUp(other.powerUpType);
        _onPowerUp(other.powerUpType);
      } else if (other is Ball) {
        if (powerUp == PowerUpType.cattch && !_caughtBalls.containsKey(other)) {
          final ball = other;
          ball.ballCanMove = false;
          _caughtBalls[ball] = _catchDuration;
        }
      }
    }
  }

  void _applyPowerUp(PowerUpType newPowerUp) {
    _normalizePowerUp();
    switch (newPowerUp) {
      case PowerUpType.cattch:
        powerUp = newPowerUp;
        break;
      case PowerUpType.extend:
        powerUp = newPowerUp;
        _starshipAnimationComponent.current = StarshipAnimation.extended;
        scale.x = 1.5;
        game.audio.play(GameSound.starshipExtends);
        break;
      case PowerUpType.laser:
        powerUp = newPowerUp;
        _starshipAnimationComponent.current =
            StarshipAnimation.laserTransforming;
        _starshipAnimationComponent.animationTicker?.reset();
        break;
      case PowerUpType.break_:
        _canEscape = true;
        break;
      case PowerUpType.slow:
      case PowerUpType.disrupt:
      case PowerUpType.player:
        break;
    }
  }

  void _normalizePowerUp() {
    releaseCaughtBalls();
    powerUp = null;
    scale.x = 1;
    _starshipAnimationComponent.current = StarshipAnimation.normal;
  }

  void _updateCaughtBalls(double dt) {
    final expired = <Ball>[];
    for (final entry in _caughtBalls.entries) {
      final remaining = entry.value - dt;
      if (remaining <= 0) {
        expired.add(entry.key);
      } else {
        _caughtBalls[entry.key] = remaining;
      }
    }
    for (final ball in expired) {
      _caughtBalls.remove(ball);
      ball.launch();
    }
  }

  void releaseCaughtBalls() {
    for (final ball in _caughtBalls.keys) {
      ball.launch();
    }
    _caughtBalls.clear();
  }

  bool get canEscape => _canEscape;

  void appear() {
    _isDisappearing = false;
    _starshipAnimationComponent.current = StarshipAnimation.appearing;
    _starshipAnimationComponent.animationTicker?.reset();
  }

  Future<void> destroy() async {
    _caughtBalls.clear();
    _isDisappearing = true;
    _normalizePowerUp();
    game.audio.play(GameSound.ballGoDown);
    _starshipAnimationComponent.current = StarshipAnimation.disappearing;
    _starshipAnimationComponent.animationTicker?.reset();
    return Future.delayed(const Duration(seconds: 2));
  }

  void performAction() {
    final level = parent;
    if (powerUp == PowerUpType.laser &&
        level != null &&
        _activeLaserVolleys < _maxActiveLaserVolleys) {
      game.audio.play(GameSound.starshipShoot);
      _activeLaserVolleys += 1;
      level.add(Laser(onRemoved: (_) => _activeLaserVolleys -= 1)
        ..position = Vector2(x + (width * scale.x / 4), y));
    }
    releaseCaughtBalls();
  }
}

class StarshipAnimationComponent
    extends SpriteAnimationGroupComponent<StarshipAnimation> {
  final double starshipWidth;
  final double starshipHeight;
  StarshipAnimationComponent(this.starshipWidth, this.starshipHeight)
      : super(size: Vector2(starshipWidth, starshipHeight));

  late final _spritesNormal = [0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(32.0, 8.0 * i),
        srcSize: Vector2(starshipWidth, starshipHeight),
      ));
  late final _spritesAppearing = [0, 1, 2, 3, 4].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(0.0, 8.0 * i),
        srcSize: Vector2(starshipWidth, starshipHeight),
      ));
  late final _spritesExtended = [0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(64.0, 8.0 * i),
        srcSize: Vector2(48, starshipHeight),
      ));
  late final _spritesLaser = [0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(144.0, 8.0 * i),
        srcSize: Vector2(32.0, starshipHeight),
      ));
  late final _spriteLaserTransforamation =
      [0, 1, 2, 3, 4, 5, 6, 7, 8].map((i) => Sprite.load(
            'starship.png',
            srcPosition: Vector2(112.0, 8.0 * i),
            srcSize: Vector2(32.0, starshipHeight),
          ));
  late final _spriteDisappearing = [0, 1, 2, 3, 4, 5, 6].map((i) => Sprite.load(
        'starship.png',
        srcPosition:
            i < 3 ? Vector2(176.0, 8.0 * i) : Vector2(16.0 + 48 * (i - 3), 76),
        srcSize: i < 3 ? Vector2(32.0, starshipHeight) : Vector2(48, 24),
      ));

  @override
  Future<void>? onLoad() async {
    animations = {
      StarshipAnimation.normal: SpriteAnimation.spriteList(
          await Future.wait(_spritesNormal),
          stepTime: 0.2),
      StarshipAnimation.appearing: SpriteAnimation.spriteList(
          await Future.wait(_spritesAppearing),
          stepTime: 0.2,
          loop: false),
      StarshipAnimation.extended: SpriteAnimation.spriteList(
          await Future.wait(_spritesExtended),
          stepTime: 0.2,
          loop: true),
      StarshipAnimation.laser: SpriteAnimation.spriteList(
          await Future.wait(_spritesLaser),
          stepTime: 0.2,
          loop: true),
      StarshipAnimation.laserTransforming: SpriteAnimation.spriteList(
          await Future.wait(_spriteLaserTransforamation),
          stepTime: 0.1,
          loop: false),
      StarshipAnimation.disappearing: SpriteAnimation.spriteList(
          await Future.wait(_spriteDisappearing),
          stepTime: 0.2,
          loop: false)
    };
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (current == StarshipAnimation.appearing &&
        animationTicker!.isLastFrame &&
        animationTicker!.elapsed >= 1) {
      current = StarshipAnimation.normal;
    }

    if (current == StarshipAnimation.laserTransforming &&
        animationTicker!.isLastFrame &&
        animationTicker!.elapsed >= 1) {
      current = StarshipAnimation.laser;
    }
  }
}
