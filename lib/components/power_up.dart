import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

//https://strategywiki.org/wiki/Arkanoid/Gameplay#Power-ups
enum PowerUpType { slow, cattch, laser, extend, disrupt, break_, player }

class PowerUp extends SpriteAnimationComponent with HasGameRef<Arkanoid> {
  final PowerUpType powerUpType;

  PowerUp(this.powerUpType) : super(size: Vector2(16, 8));

  static const spriteSheetFile = 'powerups.png';
  static const _velocity = 30.0;

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    scale *= gameRef.scaleFactor;
    SpriteSheet spriteSheet = SpriteSheet(
        image: await Flame.images.load(spriteSheetFile), srcSize: size);
    final animations = PowerUpType.values.asMap().map((key, value) => MapEntry(
        value,
        spriteSheet.createAnimation(row: key, stepTime: 0.2, loop: true)));
    animation = animations[powerUpType];
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    y += _velocity * dt * gameRef.scaleFactor;
    if (y >=
        gameRef.currentLevel.field.size.y * gameRef.currentLevel.field.scale.y +
            gameRef.currentLevel.field.position.y) {
      removeFromParent();
    }
  }
}
