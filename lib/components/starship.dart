import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/behaviours/action_behaviour.dart';
import 'package:arkanoid/components/behaviours/joystick_moving_behavior.dart';
import 'package:arkanoid/components/behaviours/keyboard_moving_behavior.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/action_entity.dart';
import 'package:arkanoid/components/laser.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/services.dart';

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
    with CollisionCallbacks, HasGameRef<Arkanoid>, ActionEntity {
  Starship._(
    this._onPowerUp,
    this._onEscape, {
    required Behavior movingBehavior,
  }) : super(
            behaviors: [
              movingBehavior,
              ActionBehaviour(fireKey: LogicalKeyboardKey.space)
            ],
            size: Vector2(starshipWidth, starshipHeight),
            anchor: Anchor.topLeft,
            children: [RectangleHitbox()],
            priority: 30);

  Starship.withJoystick({
    required JoystickComponent joystickComponent,
    required Function(PowerUpType) onPowerUp,
    required Function onEscape,
  }) : this._(
          onPowerUp,
          onEscape,
          movingBehavior: JoystickMovingBehavior(
            joystickComponent: joystickComponent,
          ),
        );

  Starship.withKeyboard(
      {required Function(PowerUpType) onPowerUp, required Function onEscape})
      : this._(
          onPowerUp,
          onEscape,
          movingBehavior: KeyboardMovingBehavior(
            leftKey: LogicalKeyboardKey.arrowLeft,
            rightKey: LogicalKeyboardKey.arrowRight,
          ),
        );

  StarshipState state = StarshipState.still;
  final StarshipAnimationComponent _starshipAnimationComponent =
      StarshipAnimationComponent(starshipWidth, starshipHeight);

  static const double starshipSpeed = 200;

  static const double starshipWidth = 32;
  static const double starshipHeight = 8;
  PowerUpType? powerUp;
  final Function(PowerUpType) _onPowerUp;
  final Function _onEscape;
  bool _isDisappearing = false;
  final List<Ball> _collidingBalls = [];
  bool _canEscape = false;
  bool _isEscaping = false;

  @override
  Future<void>? onLoad() async {
    await Flame.images.load('starship.png');
    await FlameAudio.audioCache.load('starship_extends.wav');

    scale *= gameRef.scaleFactor;
    add(_starshipAnimationComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isDisappearing) {
      if (_isEscaping) {
        state = StarshipState.escaping;
      }
      switch (state) {
        case StarshipState.movingLeft:
          x -= starshipSpeed * dt * scale.x;
          for (final ball in _collidingBalls) {
            ball.x -= starshipSpeed * dt * scale.x;
          }

          break;
        case StarshipState.movingRight:
          x += starshipSpeed * dt * scale.x;
          for (final ball in _collidingBalls) {
            ball.x += starshipSpeed * dt * scale.x;
          }

          break;
        case StarshipState.escaping:
          _isEscaping = true;
          x += 0.5;
          break;
        default:
          break;
      }

      if (state != StarshipState.escaping) {
        position.x = position.x.clamp(
          gameRef.currentLevel.field.position.x -
              (gameRef.currentLevel.field.size.x * gameRef.scaleFactor / 2) +
              Field.hitboxSize * gameRef.scaleFactor,
          gameRef.currentLevel.field.position.x +
              (gameRef.currentLevel.field.size.x * gameRef.scaleFactor / 2) -
              Field.hitboxSize * gameRef.scaleFactor -
              size.x * scale.x,
        );
      }
    }
  }

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
        _onPowerUp(other.powerUpType);
        if (powerUp != other.powerUpType) {
          powerUp = other.powerUpType;
          removePowerUp(powerUp!);
          if (powerUp == PowerUpType.extend) {
            _starshipAnimationComponent.current = StarshipAnimation.extended;
            scale.x *= 1.5;
            FlameAudio.play('starship_extends.wav');
          } else if (powerUp == PowerUpType.laser) {
            _starshipAnimationComponent.current =
                StarshipAnimation.laserTransforming;
            _starshipAnimationComponent.animationTicker?.reset();
          } else if (powerUp == PowerUpType.break_) {
            _canEscape = true;
          }
        }
      } else if (other is CompositeHitbox) {
        if (other.parent is Ball &&
            powerUp == PowerUpType.cattch &&
            !_collidingBalls.contains(other.parent as Ball)) {
          final ball = other.parent as Ball;
          ball.ballCanMove = false;
          _collidingBalls.add(ball);
        }
      }
    }
  }

  void removePowerUp(PowerUpType? newPowerUp) {
    if (newPowerUp != PowerUpType.extend) {
      scale.x = gameRef.scaleFactor;
      _starshipAnimationComponent.current = StarshipAnimation.normal;
    }
  }

  void appear() {
    _isDisappearing = false;
    _starshipAnimationComponent.current = StarshipAnimation.appearing;
    _starshipAnimationComponent.animationTicker?.reset();
  }

  Future<void> destroy() async {
    _collidingBalls.clear();
    _isDisappearing = true;
    removePowerUp(null);
    powerUp = null;
    FlameAudio.play("ball_go_down.wav");
    _starshipAnimationComponent.current = StarshipAnimation.disappearing;
    _starshipAnimationComponent.animationTicker?.reset();
    return Future.delayed(const Duration(seconds: 2));
  }

  @override
  void onActionPressed() {
    if (powerUp == PowerUpType.laser) {
      FlameAudio.play('starship_shoot.wav');
      parent?.add(Laser()..position = Vector2(x + (width * scale.x / 4), y));
    }
    for (final ball in _collidingBalls) {
      ball.ballCanMove = true;
    }
    _collidingBalls.clear();
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
            i < 3 ? Vector2(176.0, 8.0 * i) : Vector2(16.0 + 48 * i, 76),
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
