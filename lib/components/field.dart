import 'package:arkanoid/game_geometry.dart';
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

class Field extends PositionComponent with HasGameReference<Arkanoid> {
  final FieldType fieldType;
  Field(this.fieldType)
      : super(
          size: Vector2(GameGeometry.fieldWidth, GameGeometry.fieldHeight),
          anchor: Anchor.topCenter,
        );

  static const double hitboxSize = GameGeometry.wallThickness;
  static const double _sourceFieldWidth = 224;
  static const double _sliceWidth = GameGeometry.fieldWidth / 2;
  double get left => position.x - width / 2;
  double get leftWall => left + Field.hitboxSize;
  double get rightWall => left + width - Field.hitboxSize;
  double get topWall => position.y + Field.hitboxSize;
  double get lowWall => position.y + height;

  static const _fieldOrigins = <FieldType, ({double x, double y})>{
    FieldType.blue: (x: 0, y: 0),
    FieldType.green: (x: 232, y: 0),
    FieldType.electricBlue: (x: 464, y: 0),
    FieldType.electricRed: (x: 696, y: 0),
    FieldType.boss: (x: 928, y: 0),
    FieldType.darkBlue: (x: 0, y: 256),
    FieldType.darkGreen: (x: 232, y: 256),
    FieldType.darkElectricBlue: (x: 464, y: 256),
    FieldType.darkElectricRed: (x: 696, y: 256),
  };

  @override
  Future<void>? onLoad() async {
    await Flame.images.load('fields.png');
    final origin = _fieldOrigins[fieldType]!;
    await addAll([
      SpriteComponent(
        sprite: extractSprite(
          origin.x,
          origin.y,
          _sliceWidth,
          height,
          'fields.png',
        ),
        size: Vector2(_sliceWidth, height),
      ),
      SpriteComponent(
        sprite: extractSprite(
          origin.x + _sourceFieldWidth - _sliceWidth,
          origin.y,
          _sliceWidth,
          height,
          'fields.png',
        ),
        position: Vector2(_sliceWidth, 0),
        size: Vector2(_sliceWidth, height),
      ),
    ]);
    add(RectangleHitbox(size: Vector2(hitboxSize, size.y))
      ..collisionType = CollisionType.passive);
    add(RectangleHitbox(size: Vector2(hitboxSize, size.y))
      ..position = Vector2(size.x - hitboxSize, 0)
      ..collisionType = CollisionType.passive);
    add(RectangleHitbox(size: Vector2(size.x, hitboxSize))
      ..collisionType = CollisionType.passive);
  }
}
