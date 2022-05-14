import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/button_interactable.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';

enum StartshipState {
  still,
  movingLeft,
  movingRight,
  collidingLeft,
  collidingRight
}

enum StarshipAnimation { normal, appearing }

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

  StartshipState _state = StartshipState.still;

  static const double starshipSpeed = 3.5;

  static const double startshipWidth = 32;
  static const double startshipHeight = 8;

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
  @override
  Future<void>? onLoad() async {
    await Flame.images.load('starship.png');
    await FlameAudio.audioCache.load('Game_Start.ogg');
    animations = {
      StarshipAnimation.normal: SpriteAnimation.spriteList(
          await Future.wait(spritesNormal),
          stepTime: 0.2),
      StarshipAnimation.appearing: SpriteAnimation.spriteList(
          await Future.wait(spritesAppearing),
          stepTime: 0.2,
          loop: false),
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
        _state != StartshipState.collidingLeft) {
      _state = StartshipState.movingLeft;
    } else if (_joystickComponent.direction == JoystickDirection.right &&
        _state != StartshipState.collidingRight) {
      _state = StartshipState.movingRight;
    } else {
      _state = StartshipState.still;
    }
    switch (_state) {
      case StartshipState.movingLeft:
        x -= starshipSpeed;
        break;
      case StartshipState.movingRight:
        x += starshipSpeed;
        break;
      default:
        break;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Field) {
      if (_state == StartshipState.movingLeft) {
        x += starshipSpeed;
        _state = StartshipState.collidingLeft;
      } else if (_state == StartshipState.movingRight) {
        _state == StartshipState.collidingRight;
        x -= starshipSpeed;
      }
    }
  }

  @override
  void onButtonPressed() {
    print("fire!");
    //TODO: add powerup effect here
  }
}
