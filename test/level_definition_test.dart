import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/level_catalog.dart';
import 'package:arkanoid/components/levels/level_definition.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the catalog contains five ordered 16 by 13 levels', () {
    expect(
      levelCatalog.map((level) => level.roundNumber),
      orderedEquals([1, 2, 3, 4, 5]),
    );
    for (final level in levelCatalog) {
      expect(level.rows, hasLength(LevelDefinition.rowCount));
      for (final row in level.rows) {
        expect(row, hasLength(LevelDefinition.columnCount));
      }
    }
  });

  test('a definition rejects an invalid number of rows or columns', () {
    expect(
      () => LevelDefinition(
        roundNumber: 1,
        fieldType: FieldType.blue,
        rows: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => LevelDefinition(
        roundNumber: 1,
        fieldType: FieldType.blue,
        rows: [
          const [BrickSpec(BrickModel.red)],
          for (var row = 1; row < LevelDefinition.rowCount; row++)
            emptyBrickRow,
        ],
      ),
      throwsArgumentError,
    );
  });

  test('runtime bricks are recreated from immutable specs', () {
    final definition = LevelDefinition(
      roundNumber: 1,
      fieldType: FieldType.blue,
      rows: [
        const [
          BrickSpec(BrickModel.red, powerUp: PowerUpType.laser),
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
          null,
        ],
        for (var row = 1; row < LevelDefinition.rowCount; row++) emptyBrickRow,
      ],
    );

    final firstRound = definition.createBricks();
    final secondRound = definition.createBricks();

    expect(firstRound.first.first, isNot(same(secondRound.first.first)));
    expect(
      firstRound.first.first!.powerUp,
      isNot(same(secondRound.first.first!.powerUp)),
    );
    expect(() => definition.rows.add(emptyBrickRow), throwsUnsupportedError);
    expect(() => definition.rows.first.add(null), throwsUnsupportedError);
  });
}
