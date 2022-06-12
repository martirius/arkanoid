import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/power_up.dart';

class Level2 extends BaseLevel {
  Level2() : super(FieldType.green, 2);

  @override
  Future<void> onLoad() async {
    final brickSize = (gameRef.size.x - (Field.hitboxSize * 2)) /
        BaseLevel.numerOfBricEachRow;
    bricks = [
      [
        Brick(BrickModel.grey, PowerUp(PowerUpType.bonus), brickSize),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, null, brickSize),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, PowerUp(PowerUpType.extend), brickSize),
        Brick(BrickModel.green, null, brickSize),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, null, brickSize),
        Brick(BrickModel.green, PowerUp(PowerUpType.slow), brickSize),
        Brick(BrickModel.red, null, brickSize),
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, null, brickSize),
        Brick(BrickModel.green, null, brickSize),
        Brick(BrickModel.red, null, brickSize),
        Brick(BrickModel.blue, null, brickSize),
        null,
        null,
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, null, brickSize),
        Brick(BrickModel.green, null, brickSize),
        Brick(BrickModel.red, PowerUp(PowerUpType.laser), brickSize),
        Brick(BrickModel.blue, null, brickSize),
        Brick(BrickModel.pink, null, brickSize),
        null,
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, PowerUp(PowerUpType.laser), brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, null, brickSize),
        Brick(BrickModel.green, null, brickSize),
        Brick(BrickModel.red, null, brickSize),
        Brick(BrickModel.blue, null, brickSize),
        Brick(BrickModel.pink, null, brickSize),
        Brick(BrickModel.yellow, PowerUp(PowerUpType.cattch), brickSize),
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, null, brickSize),
        Brick(BrickModel.green, PowerUp(PowerUpType.slow), brickSize),
        Brick(BrickModel.red, null, brickSize),
        Brick(BrickModel.blue, null, brickSize),
        Brick(BrickModel.pink, null, brickSize),
        Brick(BrickModel.yellow, null, brickSize),
        Brick(BrickModel.grey, null, brickSize),
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, null, brickSize),
        Brick(BrickModel.green, null, brickSize),
        Brick(BrickModel.red, null, brickSize),
        Brick(BrickModel.blue, null, brickSize),
        Brick(BrickModel.pink, null, brickSize),
        Brick(BrickModel.yellow, PowerUp(PowerUpType.cattch), brickSize),
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, PowerUp(PowerUpType.extend), brickSize),
        Brick(BrickModel.green, null, brickSize),
        Brick(BrickModel.red, PowerUp(PowerUpType.laser), brickSize),
        Brick(BrickModel.blue, null, brickSize),
        Brick(BrickModel.pink, null, brickSize),
        Brick(BrickModel.yellow, null, brickSize),
        Brick(BrickModel.grey, null, brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, null, brickSize),
        null,
        null
      ],
      [
        Brick(BrickModel.grey, PowerUp(PowerUpType.laser), brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, null, brickSize),
        Brick(BrickModel.green, null, brickSize),
        Brick(BrickModel.red, null, brickSize),
        Brick(BrickModel.blue, null, brickSize),
        Brick(BrickModel.pink, null, brickSize),
        Brick(BrickModel.yellow, null, brickSize),
        Brick(BrickModel.grey, PowerUp(PowerUpType.slow), brickSize),
        Brick(BrickModel.orange, null, brickSize),
        Brick(BrickModel.lightBlue, PowerUp(PowerUpType.extend), brickSize),
        Brick(BrickModel.green, PowerUp(PowerUpType.slow), brickSize),
        null
      ],
      [
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.red, PowerUp(PowerUpType.laser), brickSize)
      ]
    ];
    super.onLoad();
  }
}
