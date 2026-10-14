import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';

class GameplayViewport extends FixedResolutionViewport {
  GameplayViewport()
      : super(
          resolution: Vector2(logicalWidth, logicalHeight),
        );

  static const logicalWidth = 224.0;
  static const logicalHeight = 240.0;
  static const screenTopMargin = 50.0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position.y = min(screenTopMargin, max(0, size.y - this.size.y));
  }
}
