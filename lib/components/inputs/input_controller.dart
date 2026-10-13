import 'package:flame/components.dart';
import 'package:flutter/services.dart';

class InputController extends Component with KeyboardHandler {
  InputController({
    required JoystickComponent joystick,
    required void Function(int direction) onMove,
    required void Function() onAction,
  })  : _joystick = joystick,
        _onMove = onMove,
        _onAction = onAction;

  final JoystickComponent _joystick;
  final void Function(int direction) _onMove;
  final void Function() _onAction;
  int _keyboardDirection = 0;

  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keyboardDirection = keysPressed.contains(LogicalKeyboardKey.arrowLeft)
        ? -1
        : keysPressed.contains(LogicalKeyboardKey.arrowRight)
            ? 1
            : 0;

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      pressAction();
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _onMove(_keyboardDirection != 0 ? _keyboardDirection : _joystickDirection);
  }

  void pressAction() => _onAction();

  int get _joystickDirection => switch (_joystick.direction) {
        JoystickDirection.left => -1,
        JoystickDirection.right => 1,
        _ => 0,
      };
}
