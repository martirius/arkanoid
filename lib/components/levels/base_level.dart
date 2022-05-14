import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/button_interactable.dart';
import 'package:arkanoid/components/inputs/inputs.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

abstract class BaseLevel extends PositionComponent
    with HasGameRef<Arkanoid>
    implements ButtonInteractable {
  BaseLevel(this.bricks, this.fieldType);

  final JoystickComponent _joystick = JoystickComponent(
      knob: Knob(),
      background: Background(),
      margin: const EdgeInsets.only(right: 40, bottom: 100),
      size: 50,
      knobRadius: 20);
  late FireButton _fireButton;
  late Starship _starship;
  final List<Ball> balls = [];
  final List<List<Brick?>> bricks;
  final FieldType fieldType;
  bool _gameStarted = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    _starship = Starship(_joystick);
    _starship.position = Vector2(
        (gameRef.size.x / 2) - _starship.size.x / 2, (gameRef.size.y / 1.8));
    _fireButton = FireButton(
      Vector2(50, size.y - ((size.y / 1.8)) / 2),
    );
    final ball = Ball();
    ball.position = Vector2((gameRef.size.x / 2) - ball.size.x / 2,
        (gameRef.size.y / 1.8) - _starship.size.y - 1);
    balls.add(ball);
    // final world = World()..add(Starship()..position = Vector2(200, 200));
    // add(world);
    // final camera = CameraComponent(world: world)
    //   ..viewfinder.visibleGameSize = Vector2(320, 480)
    //   ..viewfinder.anchor = Anchor.center;

    // add(camera);
    final field = Field(fieldType);

    add(field);
    bricks.forEach(((row) {
      for (var brick in row) {
        if (brick != null) {
          add(brick);
        }
      }
    }));
    add(_starship);
    add(_fireButton);
    add(_joystick);
    addAll(balls);
    _fireButton.addInteractable(_starship);
    _fireButton.addInteractable(this);
    _fireButton.addInteractable(ball);
  }

  @override
  void update(double dt) {
    // TODO: implement update
    super.update(dt);
    if (_gameStarted) {
      final List<Ball> ballsToRemove = [];
      for (var ball in balls) {
        if (ball.y > size.y / 2 + 100) {
          ballsToRemove.add(ball);
        }
      }
      for (var element in ballsToRemove) {
        balls.removeAt(balls.indexOf(element));
        element.removeFromParent();
      }
      if (balls.isEmpty) {
        //all balls are gone, life lost
        gameRef.pauseEngine();
      }
      final gameBricks = children.whereType<Brick>();

      //put brick as null if it doesn't exist anymore
      bricks.forEach(((row) {
        for (var brick in row.where((element) => element != null)) {
          if (!gameBricks.contains(brick) && brick != null) {
            brick = null;
          }
        }
      }));

      if (bricks.any((element) => element.any((element) => element != null))) {
        //no more brick, level completed
      }
    } else {
      balls.first.position.x = _starship.position.x + _starship.size.x / 2;
    }
  }

  static List<Brick> createBrickRow(
      int rowNum, BrickModel brickModel, PowerUpType? powerUpType) {
    return List.generate(15, (index) {
      final block =
          Brick(brickModel, powerUpType != null ? PowerUp(powerUpType) : null);
      return block
        ..position = Vector2(
            Field.hitboxSize + 2 + (block.size.x * block.scale.x) * index,
            100 +
                block.size.y * block.scale.y +
                (block.size.y * block.scale.y) * rowNum);
    });
  }

  @override
  void onButtonPressed() {
    _gameStarted = true;
  }
}
