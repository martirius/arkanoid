import 'package:arkanoid/components/levels/level1.dart';
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
  @override
  Future<void>? onLoad() async {
    super.onLoad();
    add(Level1());
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
