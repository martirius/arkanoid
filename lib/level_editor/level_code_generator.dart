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
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/power_up.dart';

class Level$_level extends BaseLevel {
  Level1() : super($_fieldType, $_level);

  @override
  Future<void> onLoad() async {
    final brickSize = (gameRef.size.x - (Field.hitboxSize * 2)) / 15;
    bricks = [
      ${_bricksString(_bricks)}
    ];
   super.onLoad();
  }
}
""", "level$_level.dart");
  }

  String _brickString(Brick brick) {
    return brick.model != null
        ? "Brick(${brick.model},${brick.powerUp != null ? "PowerUp(${brick.powerUp})" : "null"}, brickSize)"
        : "null";
  }

  String _bricksString(List<List<Brick>> bricks) {
    return _bricks
        .map((row) =>
            "[ ${row.map((brick) => _brickString(brick)).join(",\n")} ]")
        .join(",\n");
  }
}
