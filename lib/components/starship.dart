import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum StartshipState {
  still,
  movingLeft,
  movingRight,
  collidingLeft,
  collidingRight
}

class Starship extends SpriteComponent
    with CollisionCallbacks, HasGameRef<Arkanoid> {
  final JoystickComponent _joystickComponent;
  Starship(this._joystickComponent)
      : super(
            size: Vector2(startshipWidth, startshipHeight),
            scale: Vector2.all(1.5),
            anchor: Anchor.topLeft);

  @override
  bool get debugMode => true;

  StartshipState _state = StartshipState.still;

  static const double starshipSpeed = 2.5;

  static const double startshipWidth = 32;
  static const double startshipHeight = 8;

  @override
  Future<void>? onLoad() async {
    await Flame.images.load('starship.png');
    sprite = await Sprite.load(
      'starship.png',
      srcPosition: Vector2(32, 39),
      srcSize: Vector2(startshipWidth, startshipHeight),
    );
    position =
        Vector2((gameRef.size.x / 2) - size.x / 2, (gameRef.size.y / 2) + 35);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

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

  void firePressed() {
    print("fire!");
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
}
