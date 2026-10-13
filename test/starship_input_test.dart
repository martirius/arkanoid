import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keyboard movement takes priority over joystick movement', () {
    final starship = Starship.withKeyboard(
      onPowerUp: (_) {},
      onEscape: () {},
    );

    starship.setJoystickDirection(1);
    expect(starship.movementDirection, 1);

    starship.setKeyboardDirection(-1);
    expect(starship.movementDirection, -1);

    starship.setKeyboardDirection(0);
    expect(starship.movementDirection, 1);
  });

  test('starship moves at the configured horizontal speed', () {
    final game = Arkanoid()..scaleFactor = 1;
    game.currentLevel.field = Field(FieldType.blue)
      ..position = Vector2(112, 0)
      ..scale = Vector2.all(1);
    final starship = Starship.withKeyboard(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(100, 200);

    starship.setKeyboardDirection(1);
    starship.update(0.1);

    expect(starship.x, 125);
  });

  test('caught ball follows only the starship effective movement', () {
    final game = Arkanoid()..scaleFactor = 1;
    game.currentLevel.field = Field(FieldType.blue)
      ..position = Vector2(112, 0)
      ..scale = Vector2.all(1);
    final starship = Starship.withKeyboard(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(184, 200)
      ..powerUp = PowerUpType.cattch;
    final ball = Ball()..position = Vector2(200, 196);

    starship.onCollision({Vector2.zero()}, ball);
    starship.setKeyboardDirection(1);
    starship.update(1 / 60);

    expect(starship.x, 184);
    expect(ball.x, 200);
  });
}
