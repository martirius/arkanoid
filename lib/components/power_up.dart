import 'package:arkanoid/main.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

enum PowerUpType { slow, cattch, laser, extend, disrupt, bonus, player }

// TODO: add effects to each powerup
class PowerUp extends SpriteAnimationComponent with HasGameRef<Arkanoid> {
  final PowerUpType powerUpType;

  PowerUp(this.powerUpType)
      : super(size: Vector2(16, 8), scale: Vector2.all(1.5));

  static const spriteSheetFile = 'powerups.png';
  @override
  Future<void>? onLoad() async {
    super.onLoad();
    SpriteSheet spriteSheet = SpriteSheet(
        image: await Flame.images.load(spriteSheetFile), srcSize: size);
    final animations = PowerUpType.values.asMap().map((key, value) => MapEntry(
        value,
        spriteSheet.createAnimation(row: key, stepTime: 0.2, loop: true)));
    animation = animations[powerUpType];
  }

  @override
  void update(double dt) {
    super.update(dt);
    y += 1;
    if (y >= gameRef.size.y / 1.8 + 50) {
      removeFromParent();
    }
  }
}
