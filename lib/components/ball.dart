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
  Ball() : super(scale: Vector2.all(2), size: Vector2(5, 4));

  Vector2 velocity = Vector2(2, -2);
  bool ballCanMove = false;
  int _numberOfBrickHit = 0;

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    await Flame.images.load('starship.png');
    await FlameAudio.audioCache.load('ball_hit_starship.wav');

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
      if (middleIntersectionPoint.y.round() <= other.y &&
          (middleIntersectionPoint.x.round() <= other.x ||
              middleIntersectionPoint.x.round() >= other.x)) {
        //ball is over brick, invert y
        velocity.y *= -1;
      } else {
        if (middleIntersectionPoint.y.round() >= other.y + other.size.y &&
            (middleIntersectionPoint.x.round() <=
                    other.x + other.size.x * other.scale.x ||
                middleIntersectionPoint.x.round() >=
                    other.x + other.size.x * other.scale.x)) {
          velocity.y *= -1;
          //ball is below brick, inver y
        } else {
          //left or right part of brick, invert x
          velocity.x *= -1;
        }
      }
    } else if (other is Field) {
      //calculate bouncing with Field borders
      if (x - Field.hitboxSize <= 0 ||
          x + Field.hitboxSize + (size.x * scale.x) >= gameRef.size.x) {
        velocity.x *= -1;
        //left wall or right wall
      } else if (y - Field.hitboxSize - 50 <= 0) {
        //top wall
        velocity.y *= -1;
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
    if (y < gameRef.size.y / 2 + 100 && ballCanMove) {
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
