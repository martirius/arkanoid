import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/game_geometry.dart';
import 'package:arkanoid/round_rules.dart';

class BrickSpec {
  const BrickSpec(this.model, {this.powerUp});

  final BrickModel model;
  final PowerUpType? powerUp;

  Brick createBrick(RoundRules rules) => Brick(
        model,
        powerUp == null ? null : PowerUp(powerUp!),
        rules: rules,
      );
}

class LevelDefinition {
  LevelDefinition({
    required this.roundNumber,
    required this.fieldType,
    required List<List<BrickSpec?>> rows,
  })  : rules = RoundRules(roundNumber),
        rows = _validateAndFreeze(rows);

  static const rowCount = GameGeometry.brickRows;
  static const columnCount = GameGeometry.brickColumns;

  final int roundNumber;
  final RoundRules rules;
  final FieldType fieldType;
  final List<List<BrickSpec?>> rows;

  List<List<Brick?>> createBricks() => [
        for (final row in rows)
          [for (final spec in row) spec?.createBrick(rules)],
      ];

  static List<List<BrickSpec?>> _validateAndFreeze(
    List<List<BrickSpec?>> rows,
  ) {
    if (rows.length != rowCount) {
      throw ArgumentError.value(
        rows.length,
        'rows',
        'A level must contain exactly $rowCount rows',
      );
    }
    for (var index = 0; index < rows.length; index++) {
      if (rows[index].length != columnCount) {
        throw ArgumentError.value(
          rows[index].length,
          'rows[$index]',
          'A row must contain exactly $columnCount columns',
        );
      }
    }
    return List<List<BrickSpec?>>.unmodifiable(
      rows.map((row) => List<BrickSpec?>.unmodifiable(row)),
    );
  }
}

List<List<BrickSpec?>> centerLegacyArcadeRows(
  List<List<BrickSpec?>> rows,
) {
  const legacyColumnCount = 13;
  return [
    for (final row in rows)
      if (row.length == LevelDefinition.columnCount)
        row
      else if (row.length == legacyColumnCount)
        row.sublist(1, legacyColumnCount - 1)
      else
        throw ArgumentError.value(
          row.length,
          'row',
          'A legacy row must contain $legacyColumnCount columns',
        ),
  ];
}

const emptyBrickRow = <BrickSpec?>[
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
];
