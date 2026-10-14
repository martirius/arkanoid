import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/level_catalog.dart';
import 'package:arkanoid/components/levels/level_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the catalog contains 32 ordered 16 by 13 arcade rounds', () {
    expect(
      levelCatalog.map((level) => level.roundNumber),
      orderedEquals(List.generate(32, (index) => index + 1)),
    );
    for (final level in levelCatalog) {
      expect(level.rows, hasLength(LevelDefinition.rowCount));
      for (final row in level.rows) {
        expect(row, hasLength(LevelDefinition.columnCount));
      }
    }
  });

  test('arcade rounds contain the expected number of breakable bricks', () {
    const expectedBreakableBricks = [
      78,
      91,
      64,
      140,
      98,
      81,
      98,
      7,
      34,
      41,
      72,
      8,
      72,
      91,
      148,
      72,
      67,
      56,
      57,
      23,
      26,
      80,
      94,
      75,
      66,
      19,
      78,
      64,
      92,
      78,
      92,
      38,
    ];

    for (var index = 0; index < levelCatalog.length; index++) {
      final breakableBricks = levelCatalog[index]
          .rows
          .expand((row) => row)
          .where((brick) => brick != null && brick.model != BrickModel.gold)
          .length;
      expect(
        breakableBricks,
        expectedBreakableBricks[index],
        reason: 'Unexpected breakable brick count in round ${index + 1}',
      );
    }
  });

  test('provisional capsule markers only use colored breakable bricks', () {
    for (final level in levelCatalog.skip(5)) {
      for (final brick
          in level.rows.expand((row) => row).whereType<BrickSpec>()) {
        if (brick.dropsCapsule) {
          expect(brick.model, isNot(anyOf(BrickModel.silver, BrickModel.gold)));
        }
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
          BrickSpec(BrickModel.red, dropsCapsule: true),
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
    expect(firstRound.first.first!.dropsCapsule, isTrue);
    expect(secondRound.first.first!.dropsCapsule, isTrue);
    expect(() => definition.rows.add(emptyBrickRow), throwsUnsupportedError);
    expect(() => definition.rows.first.add(null), throwsUnsupportedError);
  });
}
