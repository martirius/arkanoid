import 'dart:math' as math;

import 'package:flame/components.dart';

enum EnemyType { konerd, pyradok, triSphere, opopo }

enum EnemyMotionPhase { exiting, flying, followingPattern }

typedef _MotionSegment = ({int direction, int duration});

class ArcadeEnemyMotion {
  ArcadeEnemyMotion({
    required this.type,
    math.Random? random,
  }) : _random = random ?? math.Random();

  static const framesPerSecond = 60.0;
  static const _pixelsPerTick = 0.5;
  static const _collisionHeadingTicks = 8.0;

  // Obstacle-pattern pairs decoded from the arcade tables at 0x4cc7-0x4dea.
  // They are activated after free flight, not while leaving the gate.
  static const _leftPaths = {
    EnemyType.konerd: <_MotionSegment>[
      (direction: 0x0b, duration: 0x30),
      (direction: 0x0a, duration: 0x10),
      (direction: 0x09, duration: 0x20),
      (direction: 0x08, duration: 0x38),
      (direction: 0x07, duration: 0x08),
      (direction: 0x05, duration: 0x08),
      (direction: 0x04, duration: 0x08),
      (direction: 0x02, duration: 0x08),
      (direction: 0x01, duration: 0x08),
      (direction: 0x00, duration: 0x08),
      (direction: 0x1c, duration: 0x08),
      (direction: 0x1a, duration: 0x08),
      (direction: 0x19, duration: 0x08),
      (direction: 0x18, duration: 0x2d),
      (direction: 0x17, duration: 0x08),
      (direction: 0x16, duration: 0x08),
      (direction: 0x15, duration: 0x08),
      (direction: 0x14, duration: 0x08),
      (direction: 0x13, duration: 0x28),
      (direction: 0x12, duration: 0x08),
      (direction: 0x11, duration: 0x08),
      (direction: 0x10, duration: 0x08),
      (direction: 0x0e, duration: 0x04),
      (direction: 0x0c, duration: 0x04),
    ],
    EnemyType.pyradok: <_MotionSegment>[
      (direction: 0x0e, duration: 0x28),
      (direction: 0x0d, duration: 0x26),
      (direction: 0x0a, duration: 0x15),
      (direction: 0x09, duration: 0x18),
      (direction: 0x08, duration: 0x1f),
      (direction: 0x04, duration: 0x1a),
      (direction: 0x01, duration: 0x0e),
      (direction: 0x1c, duration: 0x0e),
      (direction: 0x19, duration: 0x10),
      (direction: 0x17, duration: 0x1a),
      (direction: 0x16, duration: 0x28),
      (direction: 0x14, duration: 0x13),
      (direction: 0x12, duration: 0x15),
      (direction: 0x10, duration: 0x0e),
      (direction: 0x0d, duration: 0x1c),
    ],
    EnemyType.triSphere: <_MotionSegment>[
      (direction: 0x0a, duration: 0x11),
      (direction: 0x0e, duration: 0x34),
      (direction: 0x0b, duration: 0x11),
      (direction: 0x08, duration: 0x11),
      (direction: 0x05, duration: 0x11),
      (direction: 0x02, duration: 0x34),
      (direction: 0x06, duration: 0x11),
    ],
    EnemyType.opopo: <_MotionSegment>[
      (direction: 0x0f, duration: 0x24),
      (direction: 0x0d, duration: 0x39),
      (direction: 0x0a, duration: 0x1c),
      (direction: 0x09, duration: 0x24),
      (direction: 0x08, duration: 0x30),
      (direction: 0x06, duration: 0x24),
      (direction: 0x04, duration: 0x1c),
      (direction: 0x01, duration: 0x10),
      (direction: 0x1d, duration: 0x13),
      (direction: 0x1a, duration: 0x18),
      (direction: 0x19, duration: 0x26),
      (direction: 0x18, duration: 0x21),
      (direction: 0x16, duration: 0x28),
      (direction: 0x15, duration: 0x26),
      (direction: 0x13, duration: 0x15),
      (direction: 0x11, duration: 0x26),
    ],
  };

  final EnemyType type;
  final math.Random _random;
  List<_MotionSegment>? _path;
  EnemyMotionPhase _phase = EnemyMotionPhase.exiting;
  int _segmentIndex = 0;
  int _direction = 0x10;
  int _speedStage = 1;
  double _remaining = 0;

  EnemyMotionPhase get phase => _phase;
  int get direction => _direction;
  int get speedStage => _speedStage;
  Vector2 get velocity => _velocityFor(_direction, _speedStage);

  static List<_MotionSegment> _pathFor(EnemyType type, bool startsOnLeft) {
    final path = _leftPaths[type]!;
    if (startsOnLeft) {
      return path;
    }
    return [
      for (final segment in path)
        (
          direction: (-segment.direction) & 0x1f,
          duration: segment.duration,
        ),
    ];
  }

  Vector2 advance(double dt) {
    if (_phase != EnemyMotionPhase.followingPattern) {
      return velocity..scale(dt);
    }

    var ticks = dt * framesPerSecond;
    final displacement = Vector2.zero();
    while (ticks > 0) {
      final segmentTicks = _remaining / _speedStage;
      final elapsedTicks = math.min(ticks, segmentTicks);
      displacement.add(
        _velocityFor(_direction, _speedStage)
          ..scale(elapsedTicks / framesPerSecond),
      );
      ticks -= elapsedTicks;
      _remaining -= elapsedTicks * _speedStage;
      if (_remaining <= 0) {
        _loadSegment((_segmentIndex + 1) % _path!.length);
      }
    }
    return displacement;
  }

  void finishGateExit() {
    if (_phase != EnemyMotionPhase.exiting) {
      return;
    }
    _phase = EnemyMotionPhase.flying;
    _direction = _random.nextInt(32);
  }

  void startObstaclePattern({required bool onLeftSide}) {
    if (_phase != EnemyMotionPhase.flying) {
      return;
    }
    _phase = EnemyMotionPhase.followingPattern;
    _path = _pathFor(type, onLeftSide);
    _speedStage = switch (type) {
      EnemyType.konerd || EnemyType.opopo => math.min(15, _speedStage + 1),
      EnemyType.pyradok => math.max(1, _speedStage - 1),
      EnemyType.triSphere => _speedStage,
    };
    _loadSegment(0);
  }

  void reflectFromObstacle({required bool bounceX}) {
    if (bounceX) {
      reflectX();
    } else {
      reflectY();
    }
  }

  void turnFromHorizontalBoundary({required bool onLeftSide}) {
    if (_phase != EnemyMotionPhase.followingPattern) {
      reflectX();
      return;
    }
    _path = _pathFor(type, onLeftSide);
    _loadSegment(0);
  }

  void reflectX() {
    final reflected = (-_direction) & 0x1f;
    final expectedSign = -velocity.x.sign;
    _direction = _withArcadeVariation(reflected);
    if (velocity.x.sign != expectedSign) {
      _direction = reflected;
    }
    _remaining = math.max(_remaining, _collisionHeadingTicks);
  }

  void reflectY() {
    final reflected = (16 - _direction) & 0x1f;
    final expectedSign = -velocity.y.sign;
    _direction = _withArcadeVariation(reflected);
    if (velocity.y.sign != expectedSign) {
      _direction = reflected;
    }
    _remaining = math.max(_remaining, _collisionHeadingTicks);
  }

  void headAwayFrom(Vector2 normal) {
    if (normal.length2 == 0) {
      return;
    }
    final angle = math.atan2(normal.x, -normal.y);
    _direction = ((angle / (2 * math.pi) * 32).round()) & 0x1f;
    _remaining = _collisionHeadingTicks;
  }

  void _loadSegment(int index) {
    _segmentIndex = index;
    final segment = _path![index];
    _direction = segment.direction;
    _remaining = segment.duration.toDouble();
  }

  int _withArcadeVariation(int direction) {
    return (direction + _random.nextInt(5) - 2) & 0x1f;
  }

  static Vector2 _velocityFor(int direction, int speedStage) {
    final angle = direction * math.pi / 16;
    final pixelsPerSecond = _pixelsPerTick * framesPerSecond * speedStage;
    return Vector2(
      math.sin(angle) * pixelsPerSecond,
      -math.cos(angle) * pixelsPerSecond,
    );
  }
}
