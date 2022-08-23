import 'package:arkanoid/components/starship.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/services.dart';

class KeyboardMovingBehavior extends Behavior<Starship> with KeyboardHandler {
  final LogicalKeyboardKey leftKey;
  final LogicalKeyboardKey rightKey;

  KeyboardMovingBehavior({
    required this.leftKey,
    required this.rightKey,
  });

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(leftKey) &&
        parent.state != StarshipState.escaping) {
      parent.state = StarshipState.movingLeft;
    } else if (keysPressed.contains(rightKey)) {
      parent.state = StarshipState.movingRight;
    } else {
      parent.state = StarshipState.still;
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
