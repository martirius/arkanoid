import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

enum BreakAnimationState { opening, open }

class BreakAnimationComponent
    extends SpriteAnimationGroupComponent<BreakAnimationState> {
  BreakAnimationComponent(this._scaleFactor)
      : super(size: Vector2(_width, _height));

  static const double _height = 40;
  static const double _width = 8;
  final double _scaleFactor;

  late final _spritesOpening = [0, 1, 2].map((i) => Sprite.load(
        'fields.png',
        srcPosition: Vector2(924.0 + _width * i, 256.0),
        srcSize: Vector2(_width, _height),
      ));
  late final _spritesOpen = [0, 1, 2].map((i) => Sprite.load(
        'fields.png',
        srcPosition: Vector2(948.0 + _width * i, 256.0),
        srcSize: Vector2(_width, _height),
      ));

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    await Flame.images.load('fields.png');
    scale *= _scaleFactor;
    animations = {
      BreakAnimationState.opening: SpriteAnimation.spriteList(
          await Future.wait(_spritesOpening),
          stepTime: 0.2,
          loop: false),
      BreakAnimationState.open: SpriteAnimation.spriteList(
          await Future.wait(_spritesOpen),
          stepTime: 0.1,
          loop: true),
    };
    add(RectangleComponent(
      position: Vector2(-_width / 2, _height / 2),
      size: Vector2(_width, 1),
    )..setColor(Colors.white));
    current = BreakAnimationState.opening;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (current == BreakAnimationState.opening &&
        animationTicker!.isLastFrame) {
      current = BreakAnimationState.open;
    }
  }
}
