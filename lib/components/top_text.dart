import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// This class is used to display text with label and content.
/// Label is red and can blink if blinkLabel function is called
/// Content instead is white and cannot blink
class TopText extends PositionComponent {
  TopText(this._label, this._message);

  final String _label;
  String _message;

  late final TextComponent _labelComponent;
  late final TextComponent _messageComponent;
  late final Timer _blinkTimer = Timer(
    1,
    onTick: () {
      _isRed = !_isRed;
      if (_isRed) {
        _setLabelTransparent();
      } else {
        _setLabelRed();
      }
    },
    repeat: true,
    autoStart: false,
  );
  bool _isRed = true;

  @override
  Future<void>? onLoad() async {
    _labelComponent = TextComponent(
      text: _label,
      textRenderer: TextPaint(
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 0, 0),
            fontFamily: 'Joystix',
            fontSize: 18,
          ),
          textDirection: TextDirection.ltr),
    );
    await add(_labelComponent);

    _messageComponent = TextComponent(
        text: _message,
        textRenderer: TextPaint(
            style: const TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontFamily: 'Joystix',
                fontSize: 18),
            textDirection: TextDirection.ltr),
        position: Vector2(
          _labelComponent.x + _labelComponent.width,
          _labelComponent.y + _labelComponent.height,
        ),
        anchor: Anchor.topRight);
    await add(_messageComponent);
    super.onLoad();
  }

  void blinkLabel() {
    _blinkTimer.start();
  }

  void stopBlinkLabel() {
    _blinkTimer.stop();
  }

  void _setLabelRed() {
    _labelComponent.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color.fromARGB(255, 255, 0, 0),
          fontFamily: 'Joystix',
          fontSize: 18,
        ),
        textDirection: TextDirection.ltr);
  }

  void _setLabelTransparent() {
    _labelComponent.textRenderer = TextPaint(
        style: const TextStyle(
          color: Color.fromARGB(0, 0, 0, 0),
          fontFamily: 'Joystix',
          fontSize: 18,
        ),
        textDirection: TextDirection.ltr);
  }

  void updateMessage(String message) {
    _message = message;
    _messageComponent.text = _message;
  }

  @override
  void onRemove() {
    stopBlinkLabel();
    for (var element in children) {
      element.removeFromParent();
    }
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _blinkTimer.update(dt);
  }
}
