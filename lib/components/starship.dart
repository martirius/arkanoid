import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/button_interactable.dart';
import 'package:arkanoid/components/laser.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';

enum StarshipState {
  still,
  movingLeft,
  movingRight,
  collidingLeft,
  collidingRight
}

enum StarshipAnimation {
  normal,
  appearing,
  extended,
  laser,
  laserTransforming,
  disappearing
}

class Starship extends SpriteAnimationGroupComponent<StarshipAnimation>
    with CollisionCallbacks, HasGameRef<Arkanoid>
    implements ButtonInteractable {
  final JoystickComponent _joystickComponent;
  Starship(this._joystickComponent)
      : super(
            size: Vector2(startshipWidth, startshipHeight),
            scale: Vector2.all(1.5),
            anchor: Anchor.topLeft);

  StarshipState _state = StarshipState.still;

  static const double starshipSpeed = 4;

  static const double startshipWidth = 32;
  static const double startshipHeight = 8;
  PowerUpType? powerUp;
  bool _isDisappearing = false;

  late final _spritesNormal = [0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(32.0, 8.0 * i),
        srcSize: Vector2(startshipWidth, startshipHeight),
      ));
  late final _spritesAppearing = [0, 1, 2, 3, 4].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(0.0, 8.0 * i),
        srcSize: Vector2(startshipWidth, startshipHeight),
      ));
  late final _spritesExtended = [0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(64.0, 8.0 * i),
        srcSize: Vector2(48, startshipHeight),
      ));
  late final _spritesLaser = [0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(144.0, 8.0 * i),
        srcSize: Vector2(32.0, startshipHeight),
      ));
  late final _spriteLaserTransforamation =
      [0, 1, 2, 3, 4, 5, 6, 7, 8].map((i) => Sprite.load(
            'starship.png',
            srcPosition: Vector2(112.0, 8.0 * i),
            srcSize: Vector2(32.0, startshipHeight),
          ));
  late final _spriteDisappearing = [0, 1, 2, 3, 4, 5, 6].map((i) => Sprite.load(
        'starship.png',
        srcPosition:
            i < 3 ? Vector2(176.0, 8.0 * i) : Vector2(16.0 + 48 * i, 76),
        srcSize: i < 3 ? Vector2(32.0, startshipHeight) : Vector2(48, 24),
      ));
  @override
  Future<void>? onLoad() async {
    await Flame.images.load('starship.png');
    await FlameAudio.audioCache.load('starship_extends.wav');

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
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isDisappearing) {
      if (current == StarshipAnimation.appearing &&
          animation!.isLastFrame &&
          animation!.elapsed >= 1) {
        current = StarshipAnimation.normal;
      }

      if (current == StarshipAnimation.laserTransforming &&
          animation!.isLastFrame &&
          animation!.elapsed >= 1) {
        current = StarshipAnimation.laser;
      }

      if (_joystickComponent.direction == JoystickDirection.left &&
          _state != StarshipState.collidingLeft) {
        _state = StarshipState.movingLeft;
      } else if (_joystickComponent.direction == JoystickDirection.right &&
          _state != StarshipState.collidingRight) {
        _state = StarshipState.movingRight;
      } else {
        _state = StarshipState.still;
      }
      switch (_state) {
        case StarshipState.movingLeft:
          x -= starshipSpeed;
          break;
        case StarshipState.movingRight:
          x += starshipSpeed;
          break;
        //this case when expaning
        case StarshipState.collidingRight:
          x -= starshipSpeed;
          break;
        default:
          break;
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Field) {
      if (_state == StarshipState.movingLeft) {
        x += starshipSpeed;
        _state = StarshipState.collidingLeft;
      } else if (_state == StarshipState.movingRight) {
        _state == StarshipState.collidingRight;
        x -= starshipSpeed;
      }
    } else if (other is PowerUp) {
      other.removeFromParent();
      if (powerUp != other.powerUpType) {
        powerUp = other.powerUpType;
        removePowerUp(powerUp!);
        if (powerUp == PowerUpType.extend) {
          current = StarshipAnimation.extended;
          scale.x = 2.5;
          FlameAudio.play('starship_extends.wav');
        } else if (powerUp == PowerUpType.laser) {
          current = StarshipAnimation.laserTransforming;
          animation?.reset();
        }
      }
    }
  }

  void removePowerUp(PowerUpType? newPowerUp) {
    if (newPowerUp != PowerUpType.extend) {
      scale.x = 1.5;
      current = StarshipAnimation.normal;
    }
  }

  void appear() {
    _isDisappearing = false;
    current = StarshipAnimation.appearing;
    animation?.reset();
  }

  Future<void> destroy() async {
    _isDisappearing = true;
    removePowerUp(null);
    powerUp = null;
    FlameAudio.play("ball_go_down.wav");
    current = StarshipAnimation.disappearing;
    animation?.reset();
    return Future.delayed(const Duration(seconds: 2));
  }

  @override
  void onButtonPressed() {
    print("fire!");
    if (powerUp == PowerUpType.laser) {
      FlameAudio.play('starship_shoot.wav');
      parent?.add(Laser()..position = Vector2(x + (width * scale.x / 4), y));
    }
  }
}
