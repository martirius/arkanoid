import 'package:arkanoid/components/brick.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gold bricks are the only unbreakable bricks', () {
    for (final model in BrickModel.values) {
      expect(
        Brick(model, null).canBeBroken,
        model != BrickModel.gold,
        reason: 'Unexpected breakability for $model',
      );
    }
  });

  test('brick values follow the current scoring table', () {
    const expectedValues = {
      BrickModel.grey: 50,
      BrickModel.orange: 60,
      BrickModel.lightBlue: 70,
      BrickModel.green: 80,
      BrickModel.red: 90,
      BrickModel.blue: 100,
      BrickModel.pink: 110,
      BrickModel.yellow: 120,
      BrickModel.silver: 200,
      BrickModel.gold: 40,
    };

    for (final entry in expectedValues.entries) {
      expect(
        Brick(entry.key, null).value,
        entry.value,
        reason: 'Unexpected score for ${entry.key}',
      );
    }
  });
}
