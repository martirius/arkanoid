import 'package:arkanoid/components/starship.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

class JoystickMovingBehavior extends Behavior<Starship> {
  final JoystickComponent joystickComponent;

  JoystickMovingBehavior({required this.joystickComponent});

  @override
  void update(double dt) {
    if (parent.state != StarshipState.escaping) {
      if (joystickComponent.direction == JoystickDirection.left) {
        parent.state = StarshipState.movingLeft;
      } else if (joystickComponent.direction == JoystickDirection.right) {
        parent.state = StarshipState.movingRight;
      } else {
        parent.state = StarshipState.still;
      }
    }
    super.update(dt);
  }
}
