import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/input_controller.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keyboard movement takes priority over joystick movement', () {
    var movementDirection = 0;
    final joystick = JoystickComponent(
      knob: CircleComponent(radius: 1),
      size: 10,
    )..delta.x = 5;
    final controller = InputController(
      joystick: joystick,
      onMove: (direction) => movementDirection = direction,
      onAction: () {},
    );

    controller.update(0);
    expect(movementDirection, 1);

    controller.onKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowLeft,
        logicalKey: LogicalKeyboardKey.arrowLeft,
        timeStamp: Duration.zero,
      ),
      {LogicalKeyboardKey.arrowLeft},
    );
    controller.update(0);
    expect(movementDirection, -1);

    controller.onKeyEvent(
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.arrowLeft,
        logicalKey: LogicalKeyboardKey.arrowLeft,
        timeStamp: Duration.zero,
      ),
      {},
    );
    controller.update(0);
    expect(movementDirection, 1);
  });

  test('action fires once for a physical key press', () {
    var actions = 0;
    final controller = InputController(
      joystick: JoystickComponent(
        knob: CircleComponent(radius: 1),
        size: 10,
      ),
      onMove: (_) {},
      onAction: () => actions++,
    );

    controller.onKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration.zero,
      ),
      {LogicalKeyboardKey.space},
    );
    controller.onKeyEvent(
      const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration(milliseconds: 10),
      ),
      {LogicalKeyboardKey.space},
    );

    expect(actions, 1);
  });

  test('starship moves at the configured horizontal speed', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final starship = Starship(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(100, 200);

    starship.setMovementDirection(1);
    starship.update(0.1);

    expect(starship.x, 125);
  });

  test('caught ball follows only the starship effective movement', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final starship = Starship(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(184, 200)
      ..powerUp = PowerUpType.cattch;
    final ball = Ball()..position = Vector2(200, 196);

    starship.onCollision({Vector2.zero()}, ball);
    starship.setMovementDirection(1);
    starship.update(1 / 60);

    expect(starship.x, 184);
    expect(ball.x, 200);
  });

  test('catch releases a ball automatically after four seconds', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final starship = Starship(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(100, 200)
      ..powerUp = PowerUpType.cattch;
    final ball = Ball()
      ..position = Vector2(110, 196)
      ..ballCanMove = true;

    starship.onCollision({Vector2.zero()}, ball);
    expect(ball.ballCanMove, isFalse);

    starship.update(4);
    expect(ball.ballCanMove, isTrue);
  });
}
