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
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(leftKey)) {
      parent.setKeyboardDirection(-1);
    } else if (keysPressed.contains(rightKey)) {
      parent.setKeyboardDirection(1);
    } else {
      parent.setKeyboardDirection(0);
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
