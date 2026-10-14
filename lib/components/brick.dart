import 'package:arkanoid/main.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/round_rules.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum BrickModel {
  grey,
  orange,
  lightBlue,
  green,
  red,
  blue,
  pink,
  yellow,
  silver,
  gold
}

class Brick extends SpriteAnimationComponent with HasGameReference<Arkanoid> {
  late final bool canBeBroken;
  late final int _numberOfHitToBroke;
  final BrickModel model;
  final bool dropsCapsule;
  void Function()? onDestroyed;
  late final int value;
  static const int _baseBrickValue = 50;
  Brick(this.model, {this.dropsCapsule = false, RoundRules? rules})
      : rules = rules ?? RoundRules(1),
        super(size: Vector2(16, 8)) {
    canBeBroken = model != BrickModel.gold;
    _numberOfHitToBroke =
        model == BrickModel.silver ? this.rules.silverBrickHits : 1;
    value = model == BrickModel.silver
        ? this.rules.silverBrickPoints
        : _baseBrickValue + 10 * singleSpriteAnimationBricks.indexOf(model);
  }

  final RoundRules rules;

  late final Map<BrickModel, SpriteAnimation> animations;
  int _numberOfTimeHit = 0;
  bool _isDestroyed = false;
  static final singleSpriteAnimationBricks = [
    BrickModel.grey,
    BrickModel.orange,
    BrickModel.lightBlue,
    BrickModel.green,
    BrickModel.red,
    BrickModel.blue,
    BrickModel.pink,
    BrickModel.yellow
  ];

  @override
  Future<void>? onLoad() async {
    await Flame.images.load('blocks_tiles.png');
    Map<BrickModel, SpriteAnimation> breakableAnimation = {};
    for (BrickModel b in singleSpriteAnimationBricks) {
      breakableAnimation.putIfAbsent(
          b,
          () => SpriteAnimation.spriteList([
                _extraSingleBlockSprite(
                    16.0 * (singleSpriteAnimationBricks.indexOf(b) % 4),
                    8.0 * (singleSpriteAnimationBricks.indexOf(b) / 4).floor())
              ], stepTime: 1, loop: false));
    }
    animations = {
      ...breakableAnimation,
      BrickModel.silver: SpriteAnimation.spriteList(
          await Future.wait([0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
                'blocks_tiles.png',
                srcPosition: Vector2(16.0 * i, 16),
                srcSize: Vector2(width, height),
              ))),
          stepTime: 0.1,
          loop: false),
      BrickModel.gold: SpriteAnimation.spriteList(
          await Future.wait([0, 1, 2, 3, 4, 5].map((i) => Sprite.load(
                'blocks_tiles.png',
                srcPosition: Vector2(16.0 * i, 24.0),
                srcSize: Vector2(width, height),
              ))),
          stepTime: 0.1,
          loop: false),
    };
    animation = animations[model];
    add(RectangleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
    ));
    super.onLoad();
  }

  Sprite _extraSingleBlockSprite(double x, double y) {
    return extractSprite(x, y, width, height, 'blocks_tiles.png');
  }

  void hit(bool playAudio) {
    if (_isDestroyed) {
      return;
    }
    if (playAudio) {
      if (model == BrickModel.silver || model == BrickModel.gold) {
        game.audio.play(GameSound.ballHitBlockUnbreakable);
      } else {
        game.audio.play(GameSound.ballHitBlock);
      }
    }
    animationTicker?.reset();
    _numberOfTimeHit += 1;
    if (_numberOfTimeHit >= _numberOfHitToBroke && canBeBroken) {
      _isDestroyed = true;
      removeFromParent();
      onDestroyed?.call();
    }
  }
}
