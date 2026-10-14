import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/rendering.dart';

class FireButton extends CircleComponent with TapCallbacks {
  FireButton(Vector2 position, {required this.onPressed})
      : super(position: position, radius: 50, priority: 1);

  final void Function() onPressed;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawCircle(const Offset(50, 50), 50,
        Paint()..color = const Color.fromARGB(255, 138, 39, 22));
  }

  @override
  bool onTapDown(TapDownEvent event) {
    onPressed();
    return true;
  }
}
