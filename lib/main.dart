import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/level1.dart';
import 'package:arkanoid/components/levels/level2.dart';
import 'package:arkanoid/components/levels/level3.dart';
import 'package:arkanoid/components/levels/level4.dart';
import 'package:arkanoid/components/levels/level5.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  Flame.device.setPortraitUpOnly();

  final arkanoidGame = Arkanoid();
  runApp(GameWidget(game: arkanoidGame));
}

class Arkanoid extends FlameGame
    with HasCollisionDetection, HasDraggables, HasTappables {
  BaseLevel currentLevel = Level1();
  int currentScore = 0;
  late double scaleFactor;
  @override
  Future<void>? onLoad() async {
    super.onLoad();
    // the field in the original game is 224x240
    double xScale = size.x / 224.0;
    double yScale = (size.y - 50) / 240.0;
    scaleFactor = size.x < size.y ? xScale : yScale;
    add(currentLevel);
  }

  void levelCompleted(int levelNumber) {
    remove(currentLevel);
    switch (levelNumber) {
      case 1:
        currentLevel = Level2();
        break;
      case 2:
        currentLevel = Level3();
        break;
      case 3:
        currentLevel = Level4();
        break;
      case 4:
        currentLevel = Level5();
        break;
    }
    add(currentLevel);
  }
}

Sprite extractSprite(
    double x, double y, double width, double height, String spritesheet) {
  return Sprite(
    Flame.images.fromCache(spritesheet),
    srcPosition: Vector2(x, y),
    srcSize: Vector2(width, height),
  );
}
