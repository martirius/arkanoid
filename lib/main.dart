import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/inputs.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

import 'components/ball.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  Flame.device.setPortraitUpOnly();

  final arkanoidGame = Arkanoid();
  runApp(GameWidget(game: arkanoidGame));
}

class Arkanoid extends FlameGame
    with HasCollisionDetection, HasDraggables, HasTappables {
  final JoystickComponent _joystick = JoystickComponent(
      knob: Knob(),
      background: Background(),
      margin: const EdgeInsets.only(right: 40, bottom: 100),
      size: 50,
      knobRadius: 20);
  late FireButton _fireButton;
  late Starship _starship;
  late Ball _ball;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _starship = Starship(_joystick);
    _fireButton =
        FireButton(_starship, Vector2(50, size.y - ((size.y / 1.8)) / 2));
    _ball = Ball();
    // final world = World()..add(Starship()..position = Vector2(200, 200));
    // add(world);
    // final camera = CameraComponent(world: world)
    //   ..viewfinder.visibleGameSize = Vector2(320, 480)
    //   ..viewfinder.anchor = Anchor.center;

    // add(camera);
    add(Field());
    add(_starship);
    add(_fireButton);
    add(_joystick);
    add(_ball);
  }

  @override
  void update(double dt) {
    // TODO: implement update
    super.update(dt);
    if (_ball.y < size.y / 2 + 100) {
    } else {
      //ball goes under starship, life lost
      pauseEngine();
    }
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
