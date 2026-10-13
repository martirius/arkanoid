import 'dart:convert' show utf8;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' show AnchorElement;
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/level_editor/level_editor.dart';

class LevelCodeGenerator {
  final List<List<Brick>> _bricks;
  final int _level;
  final FieldType _fieldType;

  void _saveTextFile(String text, String filename) {
    AnchorElement()
      ..href =
          '${Uri.dataFromString(text, mimeType: 'text/plain', encoding: utf8)}'
      ..download = filename
      ..style.display = 'none'
      ..click();
  }

  LevelCodeGenerator(this._bricks, this._level, this._fieldType);

  void generateCode() {
    _saveTextFile("""
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/level_definition.dart';
import 'package:arkanoid/components/power_up.dart';

final level$_level = LevelDefinition(
  roundNumber: $_level,
  fieldType: $_fieldType,
  rows: [
    ${_bricksString(_bricks)}
  ],
);
""", "level$_level.dart");
  }

  String _brickString(Brick brick) {
    return brick.model != null
        ? "BrickSpec(${brick.model}${brick.powerUp != null ? ", powerUp: ${brick.powerUp}" : ""})"
        : "null";
  }

  String _bricksString(List<List<Brick>> bricks) {
    return _bricks
        .map((row) =>
            "const [ ${row.map((brick) => _brickString(brick)).join(",\n")} ]")
        .join(",\n");
  }
}
