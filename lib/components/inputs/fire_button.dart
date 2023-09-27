import 'package:arkanoid/components/inputs/button_interactable.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/rendering.dart';

class FireButton extends CircleComponent with TapCallbacks {
  final List<ButtonInteractable> _buttonInteractables = [];
  FireButton(position) : super(position: position, radius: 50);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawCircle(const Offset(50, 50), 50,
        Paint()..color = const Color.fromARGB(255, 138, 39, 22));
  }

  @override
  bool onTapDown(TapDownEvent event) {
    _buttonInteractables.forEach((element) => element.onButtonPressed());
    return true;
  }

  void addInteractable(ButtonInteractable buttonInteractable) {
    _buttonInteractables.add(buttonInteractable);
  }

  void removeInteractable(ButtonInteractable buttonInteractable) {
    _buttonInteractables.remove(buttonInteractable);
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
