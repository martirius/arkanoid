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

  Vector2 velocity = Vector2(2.5, -2.5);
  bool ballCanMove = false;
  int _numberOfBrickHit = 0;

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    await Flame.images.load('starship.png');
    await FlameAudio.audioCache.load('ball_hit_starship.wav');

    scale *= gameRef.scaleFactor;

    sprite = extractSprite(0, 40, 5, 4, 'starship.png');
    add(RectangleHitbox(
        position: Vector2(0.0, size.y / 2), size: Vector2(size.x + 1, 0.1)));
    add(RectangleHitbox(
        position: Vector2(size.x / 2, 0), size: Vector2(0.1, size.y + 1)));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    final middleIntersectionPoint =
        (intersectionPoints.first + intersectionPoints.last) / 2;
    final ballSpeed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y);

    if (other is Brick) {
      _numberOfBrickHit += 1;
      if (_numberOfBrickHit < 90 && _numberOfBrickHit % 15 == 0) {
        velocity *= 1.2;
      }
      if (middleIntersectionPoint.y.round() == other.y.round()) {
        //ball is over brick, invert y
        y = other.y - size.y * scale.y - 1;
        velocity.y *= -1;
      } else {
        if (middleIntersectionPoint.y.round() ==
            (other.y + (other.size.y * other.scale.y)).round()) {
          y = other.y + other.size.y * other.scale.y + 1;
          velocity.y *= -1;
          //ball is below brick, inver y
        } else {
          //left or right part of brick, invert x
          x = x < other.x
              ? other.x - 1
              : other.x + other.scale.x * other.size.x + 1;
          velocity.x *= -1;
        }
      }
    } else if (other is Field) {
      //calculate bouncing with Field borders
      if (x - Field.hitboxSize * gameRef.currentLevel.field.scale.x <= 0 ||
          x +
                  Field.hitboxSize * gameRef.currentLevel.field.scale.x +
                  (size.x * scale.x) +
                  1 >=
              gameRef.size.x) {
        velocity.x *= -1;
        x = x - Field.hitboxSize * gameRef.currentLevel.field.scale.x - 1 > 0
            ? (gameRef.size.x -
                    Field.hitboxSize * gameRef.currentLevel.field.scale.x) -
                (size.x * scale.x) -
                1
            : Field.hitboxSize * gameRef.currentLevel.field.scale.x + 1;
        //left wall or right wall
      } else if (y -
              Field.hitboxSize * gameRef.currentLevel.field.scale.x -
              50 <=
          0) {
        //top wall
        velocity.y *= -1;
        y = gameRef.currentLevel.field.position.y +
            Field.hitboxSize * gameRef.currentLevel.field.scale.y +
            1;
      }
    } else if (other is Starship && ballCanMove) {
      final starship = other;
      //calculate bouncing direction only if startship is lower than ball
      if (y < starship.y) {
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (y < gameRef.size.y / 1.5 && ballCanMove) {
      calculateBallDirection(1, dt);
    } else {
      //ball goes under starship, life lost
    }
  }

  void calculateBallDirection(double factor, double dt) {
    x += velocity.x;
    y += velocity.y;
  }

  @override
  void onButtonPressed() {
    ballCanMove = true;
  }
}
