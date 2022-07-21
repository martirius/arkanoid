import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/power_up.dart';

class Level2 extends BaseLevel {
  Level2() : super(FieldType.green, 2);

  @override
  Future<void> onLoad() async {
    bricks = [
      [
        Brick(BrickModel.grey, PowerUp(PowerUpType.bonus)),
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
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
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
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, null),
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
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, PowerUp(PowerUpType.extend)),
        Brick(BrickModel.green, null),
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
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, null),
        Brick(BrickModel.green, PowerUp(PowerUpType.slow)),
        Brick(BrickModel.red, null),
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
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, null),
        Brick(BrickModel.green, null),
        Brick(BrickModel.red, null),
        Brick(BrickModel.blue, null),
        null,
        null,
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, null),
        Brick(BrickModel.green, null),
        Brick(BrickModel.red, PowerUp(PowerUpType.laser)),
        Brick(BrickModel.blue, null),
        Brick(BrickModel.pink, null),
        null,
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, PowerUp(PowerUpType.laser)),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, null),
        Brick(BrickModel.green, null),
        Brick(BrickModel.red, null),
        Brick(BrickModel.blue, null),
        Brick(BrickModel.pink, null),
        Brick(BrickModel.yellow, PowerUp(PowerUpType.cattch)),
        null,
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, null),
        Brick(BrickModel.green, PowerUp(PowerUpType.slow)),
        Brick(BrickModel.red, null),
        Brick(BrickModel.blue, null),
        Brick(BrickModel.pink, null),
        Brick(BrickModel.yellow, null),
        Brick(BrickModel.grey, null),
        null,
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, null),
        Brick(BrickModel.green, null),
        Brick(BrickModel.red, null),
        Brick(BrickModel.blue, null),
        Brick(BrickModel.pink, null),
        Brick(BrickModel.yellow, PowerUp(PowerUpType.cattch)),
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        null,
        null,
        null
      ],
      [
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, PowerUp(PowerUpType.extend)),
        Brick(BrickModel.green, null),
        Brick(BrickModel.red, PowerUp(PowerUpType.laser)),
        Brick(BrickModel.blue, null),
        Brick(BrickModel.pink, null),
        Brick(BrickModel.yellow, null),
        Brick(BrickModel.grey, null),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, null),
        null,
        null
      ],
      [
        Brick(BrickModel.grey, PowerUp(PowerUpType.laser)),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, null),
        Brick(BrickModel.green, null),
        Brick(BrickModel.red, null),
        Brick(BrickModel.blue, null),
        Brick(BrickModel.pink, null),
        Brick(BrickModel.yellow, null),
        Brick(BrickModel.grey, PowerUp(PowerUpType.slow)),
        Brick(BrickModel.orange, null),
        Brick(BrickModel.lightBlue, PowerUp(PowerUpType.extend)),
        Brick(BrickModel.green, PowerUp(PowerUpType.slow)),
        null
      ],
      [
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.silver, null),
        Brick(BrickModel.red, PowerUp(PowerUpType.laser))
      ]
    ];
    super.onLoad();
  }
}
