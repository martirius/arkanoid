import 'package:arkanoid/components/starship.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/input.dart';
import 'package:flutter/rendering.dart';

class FireButton extends CircleComponent with Tappable {
  final Starship _starship;
  FireButton(this._starship, position) : super(position: position, radius: 50);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawCircle(const Offset(50, 50), 50,
        Paint()..color = const Color.fromARGB(255, 138, 39, 22));
  }

  @override
  bool onTapDown(TapDownInfo info) {
    _starship.firePressed();
    return true;
  }
}

class Knob extends CircleComponent {
  Knob() : super(radius: 20);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawCircle(const Offset(20, 20), 20,
        Paint()..color = const Color.fromARGB(255, 184, 42, 17));
  }
}

class Background extends CircleComponent {
  Background() : super(radius: 50);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawCircle(const Offset(50, 50), 50,
        Paint()..color = const Color.fromARGB(255, 146, 143, 142));
  }
}
