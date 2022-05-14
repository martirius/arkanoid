import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/power_up.dart';

class Level1 extends BaseLevel {
  Level1()
      : super([
          List.generate(15, (index) => null),
          BaseLevel.createBrickRow(1, BrickModel.silver, null),
          BaseLevel.createBrickRow(2, BrickModel.red, null),
          BaseLevel.createBrickRow(3, BrickModel.yellow, PowerUpType.cattch),
          BaseLevel.createBrickRow(4, BrickModel.blue, PowerUpType.laser),
          BaseLevel.createBrickRow(5, BrickModel.pink, PowerUpType.extend),
          BaseLevel.createBrickRow(6, BrickModel.green, PowerUpType.slow),
        ], FieldType.blue);
}
