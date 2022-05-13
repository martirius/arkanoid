import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../main.dart';

class Field extends SpriteComponent with HasGameRef<Arkanoid> {
  Field() : super(position: Vector2(0, 50));

  @override
  bool get debugMode => true;

  static const double hitboxSize = 15;

  late final _fields = [
    extractSprite(0, 0, 224, 240, 'fields.png'),
    extractSprite(232, 0, 224, 240, 'fields.png'),
    extractSprite(464, 0, 224, 240, 'fields.png'),
    extractSprite(696, 0, 224, 240, 'fields.png'),
    extractSprite(928, 0, 224, 240, 'fields.png'),
  ];

  @override
  Future<void>? onLoad() async {
    await Flame.images.load('fields.png');
    size = Vector2(gameRef.size.x, (gameRef.size.y / 1.8));
    sprite = _fields[2];
    add(RectangleHitbox(size: Vector2(hitboxSize, (gameRef.size.y / 1.8)))
      ..collisionType = CollisionType.passive);
    add(RectangleHitbox(size: Vector2(gameRef.size.x, hitboxSize))
      ..collisionType = CollisionType.passive);
    add(RectangleHitbox(
        size: Vector2(gameRef.size.x - hitboxSize, (gameRef.size.y / 1.8)))
      ..collisionType = CollisionType.passive);
  }
}
