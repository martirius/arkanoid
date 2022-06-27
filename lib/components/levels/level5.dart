import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/power_up.dart';

class Level5 extends BaseLevel {
  Level5() : super(FieldType.blue, 5);

  @override
  Future<void> onLoad() async {
    final brickSize = (gameRef.size.x - (Field.hitboxSize * 2)) /
        BaseLevel.numerOfBricEachRow;
    bricks = [
      [
        null,
        null,
        null,
        Brick(BrickModel.yellow, PowerUp(PowerUpType.laser), brickSize),
        null,
        null,
        null,
        null,
        null,
        Brick(BrickModel.yellow, null, brickSize),
        null,
        null,
        null
      ],
      [
        null,
        null,
        null,
        Brick(BrickModel.yellow, null, brickSize),
        null,
        null,
        null,
        null,
        null,
        Brick(BrickModel.yellow, null, brickSize),
        null,
        null,
        null
      ],
      [
        null,
        null,
        null,
        null,
        Brick(BrickModel.yellow, null, brickSize),
        null,
        null,
        null,
        Brick(BrickModel.yellow, null, brickSize),
        null,
        null,
        null,
        null
      ],
      [
        null,
        null,
        null,
        null,
        Brick(BrickModel.yellow, null, brickSize),
        null,
        null,
        null,
        Brick(BrickModel.yellow, PowerUp(PowerUpType.laser), brickSize),
        null,
        null,
        null,
        null
      ],
      [
        null,
        null,
        null,
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        null,
        null,
        null
      ],
      [
        null,
        null,
        null,
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        null,
        null,
        null
      ],
      [
        null,
        null,
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.red, PowerUp(PowerUpType.extend), brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.red, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        null,
        null
      ],
      [
        null,
        null,
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.red, PowerUp(PowerUpType.laser), brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.red, PowerUp(PowerUpType.bonus), brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        null,
        null
      ],
      [
        null,
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
        null
      ],
      [
        null,
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
        null
      ],
      [
        null,
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
        null
      ],
      [
        null,
        Brick(BrickModel.silver, null, brickSize),
        null,
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        null,
        Brick(BrickModel.silver, null, brickSize),
        null
      ],
      [
        null,
        Brick(BrickModel.silver, null, brickSize),
        null,
        Brick(BrickModel.silver, null, brickSize),
        null,
        null,
        null,
        null,
        null,
        Brick(BrickModel.silver, null, brickSize),
        null,
        Brick(BrickModel.silver, null, brickSize),
        null
      ],
      [
        null,
        Brick(BrickModel.silver, null, brickSize),
        null,
        Brick(BrickModel.silver, null, brickSize),
        null,
        null,
        null,
        null,
        null,
        Brick(BrickModel.silver, null, brickSize),
        null,
        Brick(BrickModel.silver, null, brickSize),
        null
      ],
      [
        null,
        null,
        null,
        null,
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        null,
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        null,
        null,
        null,
        null
      ],
      [
        null,
        null,
        null,
        null,
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        null,
        Brick(BrickModel.silver, null, brickSize),
        Brick(BrickModel.silver, null, brickSize),
        null,
        null,
        null,
        null
      ]
    ];
    super.onLoad();
  }
}
