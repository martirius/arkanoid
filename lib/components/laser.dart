import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum LaserStatus { normal, destroy }

class Laser extends SpriteAnimationGroupComponent<LaserStatus>
    with CollisionCallbacks {
  Laser() : super(size: Vector2(16, 8), scale: Vector2.all(1.5), priority: 10);

  late final spritesNormal = [
    Sprite.load(
      'starship.png',
      srcPosition: Vector2(152.0, 48.0),
      srcSize: Vector2(width, height),
    )
  ];
  late final spritesDestroing = [0, 1].map((i) => Sprite.load(
        'starship.png',
        srcPosition: Vector2(152.0, 56.0 + height * i),
        srcSize: Vector2(width, height),
      ));

  bool _brickAlreadyHit = false;

  @override
  Future<void>? onLoad() async {
    super.onLoad();

    animations = {
      LaserStatus.normal: SpriteAnimation.spriteList(
          await Future.wait(spritesNormal),
          stepTime: 1,
          loop: true),
      LaserStatus.destroy: SpriteAnimation.spriteList(
          await Future.wait(spritesDestroing),
          stepTime: 0.5,
          loop: false),
    };
    add(RectangleHitbox(position: Vector2(2, 0), size: Vector2(1, height)));
    add(RectangleHitbox(
        position: Vector2(size.x * scale.x - 2, 0), size: Vector2(1, height)));

    current = LaserStatus.normal;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Brick) {
      removeAll(children);
      if (!_brickAlreadyHit) {
        _brickAlreadyHit = true;
        removeLaserFromGame();
      }
    } else if (other is Field) {
      _brickAlreadyHit = true;
      removeLaserFromGame();
    }
  }

  void removeLaserFromGame() {
    current = LaserStatus.destroy;
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_brickAlreadyHit) {
      y -= 4;
    }
  }
}
