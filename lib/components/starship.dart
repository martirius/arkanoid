import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/button_interactable.dart';
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

enum StarshipAnimation { normal, appearing, extended }

class Starship extends SpriteAnimationGroupComponent<StarshipAnimation>
    with CollisionCallbacks, HasGameRef<Arkanoid>
    implements ButtonInteractable {
  final JoystickComponent _joystickComponent;
  Starship(this._joystickComponent)
      : super(
            size: Vector2(startshipWidth, startshipHeight),
            scale: Vector2.all(1.5),
            anchor: Anchor.topLeft);

  @override
  bool get debugMode => true;

  StarshipState _state = StarshipState.still;

  static const double starshipSpeed = 4;

  static const double startshipWidth = 32;
  static const double startshipHeight = 8;
  PowerUpType? powerUp;

  late final spritesNormal = [0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(32.0, 8.0 * i),
        srcSize: Vector2(startshipWidth, startshipHeight),
      ));
  late final spritesAppearing = [0, 1, 2, 3, 4].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(0.0, 8.0 * i),
        srcSize: Vector2(startshipWidth, startshipHeight),
      ));
  late final spritesExtended = [0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(64.0, 8.0 * i),
        srcSize: Vector2(48, startshipHeight),
      ));
  @override
  Future<void>? onLoad() async {
    await Flame.images.load('starship.png');
    await FlameAudio.audioCache.load('Game_Start.ogg');
    await FlameAudio.audioCache.load('starship_extends.wav');
    animations = {
      StarshipAnimation.normal: SpriteAnimation.spriteList(
          await Future.wait(spritesNormal),
          stepTime: 0.2),
      StarshipAnimation.appearing: SpriteAnimation.spriteList(
          await Future.wait(spritesAppearing),
          stepTime: 0.2,
          loop: false),
      StarshipAnimation.extended: SpriteAnimation.spriteList(
          await Future.wait(spritesExtended),
          stepTime: 0.2,
          loop: true),
    };
    current = StarshipAnimation.appearing;
    add(RectangleHitbox());
    FlameAudio.play('Game_Start.ogg');
  }

  @override
  void update(double dt) {
    super.update(dt);
    //animation controller
    if (current == StarshipAnimation.appearing &&
        animation!.isLastFrame &&
        animation!.elapsed >= 1) {
      current = StarshipAnimation.normal;
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

        if (powerUp == PowerUpType.extend) {
          current = StarshipAnimation.extended;
          scale.x = 2.5;
          FlameAudio.play('starship_extends.wav');
        } else if (positionType == PowerUpType.laser) {}
      }
    }
  }

  @override
  void onButtonPressed() {
    print("fire!");
    //TODO: add powerup effect here
  }
}
