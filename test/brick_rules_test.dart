import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/round_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gold bricks are the only unbreakable bricks', () {
    for (final model in BrickModel.values) {
      expect(
        Brick(model).canBeBroken,
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
      BrickModel.silver: 400,
      BrickModel.gold: 40,
    };

    for (final entry in expectedValues.entries) {
      expect(
        Brick(entry.key).value,
        entry.value,
        reason: 'Unexpected score for ${entry.key}',
      );
    }
  });

  test('a brick reports its destruction only once', () {
    var destructions = 0;
    final brick = Brick(BrickModel.red)..onDestroyed = () => destructions += 1;

    brick.hit(false);
    brick.hit(false);

    expect(destructions, 1);
  });

  test('silver brick rules grow every eight rounds', () {
    const expectedRules = {
      1: (hits: 2, points: 400),
      8: (hits: 2, points: 400),
      9: (hits: 3, points: 600),
      16: (hits: 3, points: 600),
      17: (hits: 4, points: 800),
      24: (hits: 4, points: 800),
      25: (hits: 5, points: 1000),
      32: (hits: 5, points: 1000),
    };

    for (final entry in expectedRules.entries) {
      final rules = RoundRules(entry.key);
      expect(rules.silverBrickHits, entry.value.hits);
      expect(rules.silverBrickPoints, entry.value.points);
    }
  });

  test('a round 17 silver brick reports destruction after four hits', () {
    var destructions = 0;
    final brick = Brick(
      BrickModel.silver,
      rules: RoundRules(17),
    )..onDestroyed = () => destructions += 1;

    for (var hit = 0; hit < 3; hit++) {
      brick.hit(false);
    }
    expect(destructions, 0);

    brick.hit(false);
    brick.hit(false);
    expect(destructions, 1);
  });
}
