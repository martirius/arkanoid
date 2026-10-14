import 'package:flame/components.dart';
import 'package:flutter/services.dart';

class InputController extends Component with KeyboardHandler {
  InputController({
    required void Function(int direction) onMove,
    required void Function(Vector2 canvasPosition) onMoveTo,
    required void Function() onAction,
  })  : _onMove = onMove,
        _onMoveTo = onMoveTo,
        _onAction = onAction;

  final void Function(int direction) _onMove;
  final void Function(Vector2 canvasPosition) _onMoveTo;
  final void Function() _onAction;
  int _keyboardDirection = 0;

  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final left = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    final right = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);
    final direction = left == right
        ? 0
        : left
            ? -1
            : 1;
    if (direction != _keyboardDirection) {
      _keyboardDirection = direction;
      _onMove(direction);
    }

    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.enter)) {
      pressAction();
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_keyboardDirection != 0) {
      _onMove(_keyboardDirection);
    }
  }

  void moveTo(Vector2 canvasPosition) {
    if (_keyboardDirection == 0) {
      _onMoveTo(canvasPosition);
    }
  }

  void pressAction() => _onAction();
}
