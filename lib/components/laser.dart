import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum LaserStatus { normal, destroy }

class Laser extends SpriteAnimationGroupComponent<LaserStatus>
    with CollisionCallbacks, HasGameReference<Arkanoid> {
  Laser({this.onRemoved}) : super(size: Vector2(16, 8), priority: 10);

  final void Function(Laser)? onRemoved;

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
  static const _velocity = 150.0;

  bool get isActive => !_brickAlreadyHit;

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
        position: Vector2(size.x - 2, 0), size: Vector2(1, height)));

    current = LaserStatus.normal;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_brickAlreadyHit) {
      return;
    }
    if (other is Brick) {
      _brickAlreadyHit = true;
      other.hit(false);
      removeLaserFromGame();
    } else if (other is Field) {
      _brickAlreadyHit = true;
      removeLaserFromGame();
    }
  }

  void removeLaserFromGame() {
    if (current == LaserStatus.destroy) {
      return;
    }
    _brickAlreadyHit = true;
    removeAll(children);
    current = LaserStatus.destroy;
    Future.delayed(const Duration(seconds: 1), () {
      removeFromParent();
    });
  }

  @override
  void onRemove() {
    onRemoved?.call(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_brickAlreadyHit) {
      y -= _velocity * dt;
    }
  }
}
