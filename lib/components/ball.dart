import 'dart:math';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/button_interactable.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';

class Ball extends SpriteComponent
    with CollisionCallbacks, HasGameRef<Arkanoid>
    implements ButtonInteractable {
  Ball() : super(size: Vector2(5, 4));

  Vector2 velocity = Vector2(150, -150);
  bool ballCanMove = false;
  int _numberOfBrickHit = 0;
  Brick? _previousBrick;
  static const _numberOfBricksHitToIncreaseVelocity = 15;
  static const _maxBrickHitToIncreaseVelocity = 90;

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    await Flame.images.load('starship.png');
    await FlameAudio.audioCache.load('ball_hit_starship.wav');

    scale *= gameRef.scaleFactor;

    sprite = extractSprite(0, 40, 5, 4, 'starship.png');
    add(CompositeHitbox(children: [
      RectangleHitbox(
          position: Vector2(0.0, size.y / 2), size: Vector2(size.x + 1, 0.1)),
      RectangleHitbox(
          position: Vector2(size.x / 2, 0), size: Vector2(0.1, size.y + 1)),
    ]));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    final middleIntersectionPoint =
        (intersectionPoints.first + intersectionPoints.last) / 2;
    final ballSpeed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y);

    if (other is Brick && _previousBrick != other) {
      _previousBrick = other;
      other.hit(true);
      _numberOfBrickHit += 1;
      if (_numberOfBrickHit < _maxBrickHitToIncreaseVelocity &&
          _numberOfBrickHit % _numberOfBricksHitToIncreaseVelocity == 0) {
        velocity *= 1.2;
      }
      if (middleIntersectionPoint.y.round() == other.y.round() &&
          velocity.y > 0) {
        //ball is over brick, invert y
        y = other.y - size.y * scale.y - 1;
        velocity.y *= -1;
      } else {
        if (middleIntersectionPoint.y.round() ==
                (other.y + (other.size.y * other.scale.y)).round() &&
            velocity.y < 0) {
          //y = other.y + other.size.y * other.scale.y + 1;
          velocity.y *= -1;
          //ball is below brick, inver y
        } else {
          //left or right part of brick, invert x
          //x = x < other.x ? x - 1 : other.x + other.scale.x * other.size.x + 1;
          velocity.x *= -1;
        }
      }
    } else if (other is Field) {
      //calculate bouncing with Field borders
      if (x - Field.hitboxSize * gameRef.currentLevel.field.scale.x <=
              gameRef.currentLevel.field.position.x ||
          x +
                  Field.hitboxSize * gameRef.currentLevel.field.scale.x +
                  (size.x * scale.x) +
                  1 >=
              gameRef.size.x - 1) {
        velocity.x *= -1;
        //left wall or right wall
      } else {
        //top wall
        velocity.y *= -1;
      }
    } else if (other is Starship && ballCanMove) {
      final starship = other;
      //calculate bouncing direction only if startship is lower than ball
      if (y + size.y <= starship.y) {
        FlameAudio.play('ball_hit_starship.wav');
        final relativeIntersectX =
            (starship.x + (starship.width * starship.scale.x)) -
                (middleIntersectionPoint.x);
        var normalizedRelativeIntersectionX =
            (relativeIntersectX / (starship.width * starship.scale.x));
        var bounceAngle = (normalizedRelativeIntersectionX * ((pi)));
        bounceAngle = bounceAngle > pi / 2
            ? bounceAngle.clamp((pi / 2) + pi / 6, pi - pi / 6)
            : bounceAngle.clamp(0 + pi / 6, (pi / 2) - pi / 6);

        velocity.x = ballSpeed * cos(bounceAngle);
        velocity.y = ballSpeed * -sin(bounceAngle);
      }
    }
    _previousBrick = other is Brick ? other : null;
  }

  @override
  void update(double dt) {
    position.x = position.x.clamp(
      gameRef.currentLevel.field.position.x +
          Field.hitboxSize * gameRef.scaleFactor,
      gameRef.currentLevel.field.position.x +
          gameRef.currentLevel.field.size.x * gameRef.scaleFactor -
          Field.hitboxSize * gameRef.scaleFactor -
          size.x * gameRef.scaleFactor,
    );
    position.y = position.y.clamp(
        gameRef.currentLevel.field.position.y +
            Field.hitboxSize * gameRef.scaleFactor -
            1,
        gameRef.currentLevel.field.position.y +
            gameRef.currentLevel.field.size.y * gameRef.scaleFactor);
    if (y < gameRef.size.y / 1.5 && ballCanMove) {
      calculateBallDirection(1, dt);
    } else {
      //ball goes under starship, life lost
    }
  }

  void calculateBallDirection(double factor, double dt) {
    x += velocity.x * dt;
    y += velocity.y * dt;
  }

  @override
  void onButtonPressed() {
    ballCanMove = true;
  }

  void slow() {
    if (_numberOfBrickHit >= _numberOfBricksHitToIncreaseVelocity) {
      velocity /= ((_numberOfBrickHit > _maxBrickHitToIncreaseVelocity
                      ? _maxBrickHitToIncreaseVelocity
                      : _numberOfBrickHit) /
                  _numberOfBricksHitToIncreaseVelocity)
              .floor() *
          1.2;
      _numberOfBrickHit = 0;
    }
  }
}
