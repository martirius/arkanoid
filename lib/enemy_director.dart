import 'dart:ui';

import 'package:arkanoid/components/enemy.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/game_session.dart';
import 'package:flame/components.dart';

class EnemyDirector extends Component {
  EnemyDirector({
    required this.roundNumber,
    required this.field,
    required this.vausCenterX,
    required this.isPlaying,
    required this.onEnemyDestroyed,
    required this.difficulty,
  });

  static const maxActiveEnemies = 3;
  static const _initialSpawnDelay = 16 / ArcadeEnemyRules.arcadeFramesPerSecond;
  static const _gateOffsets = [56.0, 168.0];

  final int roundNumber;
  final Field Function() field;
  final double Function() vausCenterX;
  final bool Function() isPlaying;
  final void Function(Enemy) onEnemyDestroyed;
  final GameDifficulty difficulty;
  final Set<Enemy> _activeEnemies = {};
  final Set<EnemyGate> _activeGates = {};
  late final ArcadeEnemyRules _rules =
      ArcadeEnemyRules(roundNumber: roundNumber);
  double _roundElapsed = 0;
  double _initialDelayElapsed = 0;
  int _pendingSpawns = 0;
  bool _initialized = false;

  int get activeEnemyCount => _activeEnemies.length;
  Iterable<Enemy> get activeEnemies => _activeEnemies;
  double get roundElapsed => _roundElapsed;

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying() || roundNumber >= 33) {
      return;
    }
    _roundElapsed += dt;
    final slotLimit = _rules.slotLimit(
      difficulty: difficulty,
      elapsedSeconds: _roundElapsed,
    );
    if (_activeEnemies.length + _pendingSpawns >= slotLimit) {
      return;
    }
    if (!_initialized) {
      _initialDelayElapsed += dt;
      if (_initialDelayElapsed < _initialSpawnDelay) {
        return;
      }
      _initialized = true;
    }
    if (_activeGates.isNotEmpty) {
      return;
    }
    _openNextGate();
  }

  void _openNextGate() {
    final currentField = field();
    final spawn = _rules.spawnFor(
      vausCenterX: vausCenterX(),
      fieldCenterX: currentField.x,
    );
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

  void reset({bool preserveRoundTime = false}) {
    for (final enemy in _activeEnemies.toList()) {
      enemy.removeFromParent();
    }
    for (final gate in _activeGates.toList()) {
      gate.removeFromParent();
    }
    _activeEnemies.clear();
    _activeGates.clear();
    _pendingSpawns = 0;
    _initialDelayElapsed = 0;
    _initialized = false;
    if (!preserveRoundTime) {
      _roundElapsed = 0;
    }
  }

  @override
  void onRemove() {
    reset();
    super.onRemove();
  }
}

class ArcadeEnemyRules {
  const ArcadeEnemyRules({required this.roundNumber}) : assert(roundNumber > 0);

  static const arcadeFramesPerSecond = 59.185;
  static const _unlockFrames = [0x0700, 0x0e00, 0x1500];
  static const _easyInitialSlotLimits = [
    0,
    1,
    3,
    1,
    1,
    2,
    3,
    3,
    3,
    0,
    3,
    0,
    3,
    3,
    3,
    3,
    1,
    1,
    2,
    3,
    0,
    3,
    3,
    3,
    0,
    3,
    3,
    3,
    0,
    3,
    0,
    1,
  ];

  final int roundNumber;

  EnemyType get type =>
      EnemyType.values[(roundNumber - 1) % EnemyType.values.length];

  int slotLimit({
    required GameDifficulty difficulty,
    required double elapsedSeconds,
  }) {
    if (roundNumber > _easyInitialSlotLimits.length) {
      return 0;
    }
    if (difficulty == GameDifficulty.hard) {
      return EnemyDirector.maxActiveEnemies;
    }

    var limit = _easyInitialSlotLimits[roundNumber - 1];
    final elapsedFrames = elapsedSeconds * arcadeFramesPerSecond;
    for (final frame in _unlockFrames) {
      if (elapsedFrames >= frame) {
        limit += 1;
      }
    }
    return limit > EnemyDirector.maxActiveEnemies
        ? EnemyDirector.maxActiveEnemies
        : limit;
  }

  ({int gateIndex, EnemyType type}) spawnFor({
    required double vausCenterX,
    required double fieldCenterX,
  }) {
    return (
      gateIndex: vausCenterX < fieldCenterX ? 0 : 1,
      type: type,
    );
  }
}

class EnemyGate extends PositionComponent {
  EnemyGate({required this.onOpened, required this.onRemoved})
      : super(size: Vector2(24, 8), priority: 5);

  static const openingDuration = 20 / ArcadeEnemyRules.arcadeFramesPerSecond;
  static const closingDuration = 24 / ArcadeEnemyRules.arcadeFramesPerSecond;
  static const totalDuration = openingDuration + closingDuration;

  final void Function() onOpened;
  final void Function() onRemoved;
  double _elapsed = 0;
  bool _opened = false;
  bool _removalReported = false;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (!_opened && _elapsed >= openingDuration) {
      _opened = true;
      onOpened();
    }
    if (_elapsed >= totalDuration) {
      _reportRemoved();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = _elapsed <= openingDuration
        ? (_elapsed / openingDuration).clamp(0.0, 1.0)
        : ((totalDuration - _elapsed) / closingDuration).clamp(0.0, 1.0);
    final openingWidth = width * progress;
    canvas.drawRect(
      Rect.fromLTWH((width - openingWidth) / 2, 0, openingWidth, height),
      Paint()..color = const Color(0xff000000),
    );
  }

  @override
  void onRemove() {
    _reportRemoved();
    super.onRemove();
  }

  void _reportRemoved() {
    if (_removalReported) {
      return;
    }
    _removalReported = true;
    onRemoved();
  }
}
