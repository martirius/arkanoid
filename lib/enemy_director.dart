import 'dart:ui';

import 'package:arkanoid/components/enemy.dart';
import 'package:arkanoid/components/field.dart';
import 'package:flame/components.dart';

class EnemyDirector extends Component {
  EnemyDirector({
    required this.roundNumber,
    required this.field,
    required this.isPlaying,
    required this.onEnemyDestroyed,
    this.spawnInterval = 6,
  });

  static const maxActiveEnemies = 3;
  static const _gateOffsets = [56.0, 168.0];

  final int roundNumber;
  final Field Function() field;
  final bool Function() isPlaying;
  final void Function(Enemy) onEnemyDestroyed;
  final double spawnInterval;
  final Set<Enemy> _activeEnemies = {};
  final Set<EnemyGate> _activeGates = {};
  late final ArcadeEnemySequence _sequence =
      ArcadeEnemySequence(roundNumber: roundNumber);
  double _elapsed = 0;
  int _pendingSpawns = 0;

  int get activeEnemyCount => _activeEnemies.length;
  Iterable<Enemy> get activeEnemies => _activeEnemies;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying() || roundNumber >= 32) {
      return;
    }
    _elapsed += dt;
    if (_elapsed < spawnInterval ||
        _activeEnemies.length + _pendingSpawns >= maxActiveEnemies) {
      return;
    }
    _elapsed = 0;
    _openNextGate();
  }

  void _openNextGate() {
    final currentField = field();
    final spawn = _sequence.next();
    _pendingSpawns += 1;

    late final EnemyGate gate;
    gate = EnemyGate(
      onOpened: () {
        _pendingSpawns -= 1;
        if (!isPlaying() || parent == null) {
          return;
        }
        final enemy = Enemy(
          type: spawn.type,
          playArea: () {
            final activeField = field();
            return Rect.fromLTRB(
              activeField.leftWall,
              activeField.topWall,
              activeField.rightWall,
              activeField.lowWall,
            );
          },
          onDestroyed: onEnemyDestroyed,
          onRemoved: enemyRemoved,
        )..position = Vector2(
            currentField.left + _gateOffsets[spawn.gateIndex],
            currentField.topWall + 10,
          );
        _activeEnemies.add(enemy);
        parent?.add(enemy);
      },
      onRemoved: () => _activeGates.remove(gate),
    )..position = Vector2(
        currentField.left + _gateOffsets[spawn.gateIndex] - 12,
        currentField.y,
      );
    _activeGates.add(gate);
    parent?.add(gate);
  }

  void enemyRemoved(Enemy enemy) {
    _activeEnemies.remove(enemy);
  }

  void reset() {
    for (final enemy in _activeEnemies.toList()) {
      enemy.removeFromParent();
    }
    for (final gate in _activeGates.toList()) {
      gate.removeFromParent();
    }
    _activeEnemies.clear();
    _activeGates.clear();
    _pendingSpawns = 0;
    _elapsed = 0;
  }

  @override
  void onRemove() {
    reset();
    super.onRemove();
  }
}

class ArcadeEnemySequence {
  ArcadeEnemySequence({required this.roundNumber});

  final int roundNumber;
  int _spawnCount = 0;

  ({int gateIndex, EnemyType type}) next() {
    final spawn = (
      gateIndex: _spawnCount % 2,
      type: EnemyType
          .values[(roundNumber - 1 + _spawnCount) % EnemyType.values.length],
    );
    _spawnCount += 1;
    return spawn;
  }
}

class EnemyGate extends PositionComponent {
  EnemyGate({required this.onOpened, required this.onRemoved})
      : super(size: Vector2(24, 8), priority: 5);

  final void Function() onOpened;
  final void Function() onRemoved;
  double _elapsed = 0;
  bool _opened = false;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (!_opened && _elapsed >= 0.3) {
      _opened = true;
      onOpened();
    }
    if (_elapsed >= 0.6) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = _elapsed <= 0.3
        ? (_elapsed / 0.3).clamp(0.0, 1.0)
        : ((0.6 - _elapsed) / 0.3).clamp(0.0, 1.0);
    final openingWidth = width * progress;
    canvas.drawRect(
      Rect.fromLTWH((width - openingWidth) / 2, 0, openingWidth, height),
      Paint()..color = const Color(0xff000000),
    );
  }

  @override
  void onRemove() {
    onRemoved();
    super.onRemove();
  }
}
