import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/round_rules.dart';

class BrickSpec {
  const BrickSpec(this.model);

  final BrickModel model;

  Brick createBrick(RoundRules rules) => Brick(
        model,
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

  static const rowCount = 16;
  static const columnCount = 13;

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
  null,
  null,
];
