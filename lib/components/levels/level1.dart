import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/power_up.dart';

class Level1 extends BaseLevel {
  Level1() : super(FieldType.blue, 1);

  @override
  Future<void> onLoad() async {
    bricks = [
      createBrickRow(1, BrickModel.silver, null),
      createBrickRow(2, BrickModel.red, null),
      createBrickRow(3, BrickModel.yellow, PowerUpType.cattch),
      createBrickRow(4, BrickModel.blue, PowerUpType.slow),
      createBrickRow(5, BrickModel.pink, PowerUpType.extend),
      createBrickRow(6, BrickModel.green, PowerUpType.laser),
      List<Brick?>.generate(15, (index) => null)
    ];
    super.onLoad();
  }
}
