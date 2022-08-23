import 'package:arkanoid/main.dart';
import 'package:flame/components.dart';

/*
 * This components prints the number of lives user has 
 */
class Lives extends PositionComponent {
  Lives(this._numberOfLives, this._scaleFactor)
      : super(
            size: Vector2(
              _lifeWidth * _numberOfLives,
              _lifeHeight,
            ),
            scale: Vector2(_scaleFactor, _scaleFactor));

  static const _lifeHeight = 8.0;
  static const _lifeWidth = 16.0;

  final double _scaleFactor;
  int _numberOfLives;
  final List<Component> _livesComponents = [];

  @override
  Future<void>? onLoad() async {
    for (var i = 0; i < _numberOfLives; i++) {
      await addLife(false);
    }
  }

  Future<void>? addLife(bool increaseLife) {
    final lifeSprite =
        extractSprite(924, 304, _lifeWidth, _lifeHeight, 'fields.png');
    final lifeSpriteComponent = SpriteComponent(
      sprite: lifeSprite,
      size: Vector2(_lifeWidth, _lifeHeight),
      position: Vector2(_lifeWidth * _livesComponents.length, 0),
    );
    if (increaseLife) {
      _numberOfLives += 1;
    }
    _livesComponents.add(lifeSpriteComponent);
    return add(lifeSpriteComponent);
  }

  void removeLife() {
    if (_numberOfLives > 0) {
      _numberOfLives -= 1;
      remove(_livesComponents.removeLast());
    }
  }
}
