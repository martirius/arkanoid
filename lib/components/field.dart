import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum FieldType {
  blue,
  green,
  electricBlue,
  electricRed,
  darkBlue,
  darkGreen,
  darkElectricBlue,
  darkElectricRed,
  boss
}

class Field extends SpriteComponent with HasGameRef<Arkanoid> {
  final FieldType fieldType;
  Field(this.fieldType);

  @override
  bool get debugMode => true;

  static const double hitboxSize = 15;

  late final _fields = {
    FieldType.blue: extractSprite(0, 0, 224, 240, 'fields.png'),
    FieldType.green: extractSprite(232, 0, 224, 240, 'fields.png'),
    FieldType.electricBlue: extractSprite(464, 0, 224, 240, 'fields.png'),
    FieldType.electricRed: extractSprite(696, 0, 224, 240, 'fields.png'),
    FieldType.boss: extractSprite(928, 0, 224, 240, 'fields.png'),
    FieldType.darkBlue: extractSprite(0, 256, 224, 240, 'fields.png'),
    FieldType.darkGreen: extractSprite(232, 256, 224, 240, 'fields.png'),
    FieldType.darkElectricBlue: extractSprite(464, 256, 224, 240, 'fields.png'),
    FieldType.darkElectricRed: extractSprite(696, 256, 224, 240, 'fields.png'),
  };

  @override
  Future<void>? onLoad() async {
    await Flame.images.load('fields.png');
    size = Vector2(gameRef.size.x, (gameRef.size.y / 1.8));
    sprite = _fields[fieldType];
    add(RectangleHitbox(size: Vector2(hitboxSize, (gameRef.size.y / 1.8)))
      ..collisionType = CollisionType.passive);
    add(RectangleHitbox(size: Vector2(gameRef.size.x, hitboxSize))
      ..collisionType = CollisionType.passive);
    add(RectangleHitbox(
        size: Vector2(gameRef.size.x - hitboxSize, (gameRef.size.y / 1.8)))
      ..collisionType = CollisionType.passive);
  }
}
