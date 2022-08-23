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
  Field(this.fieldType)
      : super(size: Vector2(224, 240), anchor: Anchor.topCenter);

  static const double hitboxSize = 8;
  double get leftWall =>
      position.x - size.x * scale.x / 2 + Field.hitboxSize * scale.x;
  double get rightWall =>
      position.x -
      size.x * scale.x / 2 +
      (size.x * scale.x) -
      Field.hitboxSize * scale.x;
  double get topWall => position.y + Field.hitboxSize * scale.x;
  double get lowWall => position.y + size.y * scale.y;

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
    scale = Vector2(gameRef.scaleFactor, gameRef.scaleFactor);
    sprite = _fields[fieldType];
    add(RectangleHitbox(size: Vector2(hitboxSize, size.y))
      ..collisionType = CollisionType.passive);
    add(RectangleHitbox(size: Vector2(hitboxSize, size.y))
      ..position = Vector2(size.x - hitboxSize, 0)
      ..collisionType = CollisionType.passive);
    add(RectangleHitbox(size: Vector2(size.x, hitboxSize))
      ..collisionType = CollisionType.passive);
  }
}
