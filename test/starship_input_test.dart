import 'package:arkanoid/components/starship.dart';
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
}
