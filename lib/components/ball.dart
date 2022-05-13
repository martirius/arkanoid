import 'dart:math';

import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';

class Ball extends SpriteComponent
    with CollisionCallbacks, HasGameRef<Arkanoid> {
  Ball() : super(scale: Vector2.all(2), size: Vector2(5, 4));

  @override
  bool get debugMode => true;

  Vector2 velocity = Vector2(-1, -1);
  double velocityMultiplier = 1.1;

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    await Flame.images.load('starship.png');
    await FlameAudio.audioCache.load('ball_hit_starship.wav');

    sprite = extractSprite(0, 40, 5, 4, 'starship.png');
    position = Vector2(gameRef.size.x / 2 - 10, gameRef.size.y / 2 + 27);
    add(RectangleHitbox());
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Field) {
      print(x);
      print(gameRef.size.x);
      if (x - Field.hitboxSize <= 0 ||
          x + Field.hitboxSize + (size.x * scale.x) >= gameRef.size.x) {
        velocity.x *= -1;
        //left wall or right wall
      } else if (y - Field.hitboxSize - 50 <= 0) {
        //top wall
        velocity.y *= -1;
      }
    } else if (other is Starship) {
      final starship = other;
      //calculate bouncing direction only if startship is lower than ball
      if (y < starship.y) {
        FlameAudio.play('ball_hit_starship.wav');
        final middleIntersectionPoint =
            (intersectionPoints.first + intersectionPoints.last) / 2;
        final relativeIntersectX =
            (starship.x + (starship.width * starship.scale.x)) -
                (middleIntersectionPoint.x);
        var normalizedRelativeIntersectionX =
            (relativeIntersectX / (starship.width * starship.scale.x));
        var bounceAngle = normalizedRelativeIntersectionX * ((pi - pi / 12));
        velocity.x = velocityMultiplier * cos(bounceAngle);
        velocity.y = velocityMultiplier * -sin(bounceAngle);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (y < gameRef.size.y / 2 + 100) {
      calculateBallDirection(1, dt);
    } else {
      //ball goes under starship, life lost

    }
  }

  void calculateBallDirection(double factor, double dt) {
    x += velocity.x;
    y += velocity.y;
  }
}
