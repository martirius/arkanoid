import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/level1.dart';
import 'package:arkanoid/components/levels/level2.dart';
import 'package:arkanoid/components/levels/level3.dart';
import 'package:arkanoid/components/levels/level4.dart';
import 'package:arkanoid/components/levels/level5.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/widgets.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  Flame.device.setPortraitUpOnly();

  final arkanoidGame = Arkanoid();
  runApp(GameWidget(game: arkanoidGame));
}

class Arkanoid extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  BaseLevel currentLevel = Level1();
  int topScore = 50000;
  int currentScore = 0;
  int numberOfLives = 3;
  late double scaleFactor;
  @override
  Future<void>? onLoad() async {
    super.onLoad();
    await FlameAudio.audioCache.load('Game_Start.mp3');
    // the field in the original game is 224x240
    double xScale = size.x / 224.0;
    double yScale = (size.y - 50) / 240.0;
    scaleFactor = size.x < size.y ? xScale : yScale;
    add(currentLevel);
  }

  void levelCompleted(int levelNumber) {
    remove(currentLevel);
    switch (levelNumber) {
      case 0:
        currentLevel = Level1();
        break;
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

  void gameOver() {
    if (currentScore >= topScore) {
      //show name inesrtion component
    } else {
      //play again
      levelCompleted(0);
    }
    currentScore = 0;
    numberOfLives = 3;
  }

  @override
  @mustCallSuper
  KeyEventResult onKeyEvent(
    RawKeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);

    // Return handled to prevent macOS noises.
    return KeyEventResult.handled;
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
