import 'package:arkanoid/components/inputs/action_entity.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/services.dart';

class ActionBehaviour extends Behavior<ActionEntity> with KeyboardHandler {
  final LogicalKeyboardKey fireKey;

  ActionBehaviour({
    required this.fireKey,
  }) : super();

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(fireKey)) {
      parent.onActionPressed();
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
