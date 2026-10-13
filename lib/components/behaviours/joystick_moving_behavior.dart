import 'package:arkanoid/components/starship.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

class JoystickMovingBehavior extends Behavior<Starship> {
  final JoystickComponent joystickComponent;

  JoystickMovingBehavior({required this.joystickComponent});

  @override
  void update(double dt) {
    if (joystickComponent.direction == JoystickDirection.left) {
      parent.setJoystickDirection(-1);
    } else if (joystickComponent.direction == JoystickDirection.right) {
      parent.setJoystickDirection(1);
    } else {
      parent.setJoystickDirection(0);
    }
    super.update(dt);
  }
}
