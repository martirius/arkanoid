import 'dart:async' as async;

import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/break_animation.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/enemy.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/laser.dart';
import 'package:arkanoid/components/levels/level_definition.dart';
import 'package:arkanoid/components/lives.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/enemy_director.dart';
import 'package:arkanoid/main.dart';
import 'package:arkanoid/power_up_director.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/painting.dart';

enum RoundPhase {
  intro,
  ready,
  playing,
  lifeLost,
  escaping,
  completed,
  gameOver,
}

class BaseLevel extends PositionedEntity with HasGameReference<Arkanoid> {
  BaseLevel(this.definition) : fieldType = definition.fieldType;

  static const _roundReadyDuration = Duration(seconds: 2);
  static const _worldMessageFontSize = 10.0;
  static const _starshipBottomMargin = 12.0;

  final LevelDefinition definition;
  late Starship _starship;
  final List<Ball> balls = [];
  List<List<Brick?>> bricks = [];
  late Lives _lives;
  late Field field;
  late EnemyDirector _enemyDirector;
  final FieldType fieldType;
  RoundPhase _phase = RoundPhase.intro;
  final Map<async.Timer, async.Completer<bool>> _pendingRoundDelays = {};
  bool _removed = false;
  final PowerUpDirector _powerUpDirector = PowerUpDirector();
  PowerUp? _fallingPowerUp;

  RoundPhase get phase => _phase;

  late final _roundNumberComponent = TextComponent(
      text: "ROUND ${definition.roundNumber}\nREADY",
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontFamily: 'Joystix',
              fontSize: _worldMessageFontSize),
          textDirection: TextDirection.ltr),
      anchor: Anchor.center);
  late final _gameOverComponent = TextComponent(
      text: "Game\nOver",
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontFamily: 'Joystix',
              fontSize: _worldMessageFontSize),
          textDirection: TextDirection.ltr),
      anchor: Anchor.center)
    ..position = Vector2(
      field.x,
      field.y + field.height / 2,
    );

  @override
  Future<void> onLoad() async {
    bricks = definition.createBricks();
    await super.onLoad();
    await _initializeComponents();
    await _loadComponents();
  }

  @override
  void onRemove() {
    _removed = true;
    for (final entry in _pendingRoundDelays.entries.toList()) {
      entry.key.cancel();
      if (!entry.value.isCompleted) {
        entry.value.complete(false);
      }
    }
    _pendingRoundDelays.clear();
    super.onRemove();
  }

  void _onPowerUpTaken(PowerUpType powerUpType) {
    addScore(1000);
    switch (powerUpType) {
      case PowerUpType.break_:
        add(BreakAnimationComponent()
          ..anchor = Anchor.bottomRight
          ..position =
              Vector2(field.position.x + field.width / 2, field.lowWall));
        break;
      case PowerUpType.slow:
        for (var ball in balls) {
          ball.slow();
        }
        break;
      case PowerUpType.disrupt:
        final mainBall = balls.first;
        while (balls.length < 3) {
          final ball = Ball()
            ..ballCanMove = true
            ..position = mainBall.position
            ..velocity = Vector2(
                mainBall.velocity.x * (balls.length == 2 ? 0.9 : 0.8),
                mainBall.velocity.y);
          balls.add(ball);
          add(ball);
        }
        break;
      case PowerUpType.player:
        if (game.session.awardLifeCapsule()) {
          game.audio.play(GameSound.extraLife);
          _lives.addLife(true);
        }
        break;
      default:
        break;
    }
  }

  void _onStarshipEscape() {
    if (_phase != RoundPhase.playing) {
      return;
    }
    _phase = RoundPhase.escaping;
    for (var element in balls) {
      element.ballCanMove = false;
      element.removeFromParent();
    }

    game.audio.play(GameSound.wallPortalTook);
    async.unawaited(_completeEscape());
  }

  Future<void> _completeEscape() async {
    final elapsed = await _waitFor(const Duration(seconds: 4));
    if (!elapsed || !_isCurrentRound || _phase != RoundPhase.escaping) {
      return;
    }
    _phase = RoundPhase.completed;
    addScore(10000);
    game.levelCompleted(definition.roundNumber);
  }

  Future<void> _initializeComponents() async {
    size = game.size;
    _lives = Lives(game.numberOfLives)
      ..anchor = Anchor.bottomLeft
      ..priority = 20;
    _starship = _newStarship();
    field = _newField();
    _enemyDirector = _newEnemyDirector();
  }

  Future<void> _loadComponents() async {
    await _loadGameComponents();
  }

  Future<void> loadBricks() async {
    for (var rowIndex = 0; rowIndex < bricks.length; rowIndex++) {
      final row = bricks[rowIndex];
      for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
        final brick = row[columnIndex];
        if (brick != null) {
          await add(brick
            ..onDestroyed = () {
              _onBrickDestroyed(rowIndex, columnIndex, brick);
            }
            ..position = Vector2(
                field.left + Field.hitboxSize + brick.width * columnIndex,
                field.y + 20 + brick.height + brick.height * rowIndex));
        }
      }
    }
  }

  Future<void> _loadGameComponents() async {
    await add(field);
    await add(_enemyDirector);
    _positionStarship();
    _positionLives();
    final ball = _newBall();
    balls
      ..clear()
      ..add(ball);
    if (bricks.isNotEmpty) {
      await loadBricks();
    }
    await add(_roundNumberComponent
      ..priority = 100
      ..position = Vector2(field.x, field.y + field.height * 0.75));

    game.audio.play(GameSound.gameStart);
    async.unawaited(_completeRoundIntro(ball));
    // Let onLoad finish so Flame can mount and render the READY screen.
  }

  Future<void> _completeRoundIntro(Ball ball) async {
    final elapsed = await _waitFor(_roundReadyDuration);
    if (!elapsed || !_isCurrentRound || _phase != RoundPhase.intro) {
      return;
    }
    await _mountRoundComponents(ball, addLives: true);
  }

  Future<void> _mountRoundComponents(
    Ball ball, {
    required bool addLives,
  }) async {
    await add(_starship);
    _starship.appear();
    await add(ball);
    if (addLives) {
      await add(_lives);
    }
    _roundNumberComponent.removeFromParent();
    _phase = RoundPhase.ready;
    ball.ballCanMove = false;
  }

  void _positionStarship() {
    _starship.position = Vector2(
      field.x - _starship.width / 2,
      field.lowWall - _starship.height - _starshipBottomMargin,
    );
  }

  void _positionLives() {
    _lives.position = Vector2(
      field.left + Field.hitboxSize,
      field.lowWall,
    );
  }

  Future<void> _removeGameComponents() async {
    _enemyDirector.reset();
    _enemyDirector.removeFromParent();
    for (final element in children.toList()) {
      if (element is PowerUp ||
          element is BreakAnimationComponent ||
          element is Laser) {
        element.removeFromParent();
      }
    }
    _fallingPowerUp = null;
    for (final element in balls) {
      element.removeFromParent();
    }
    balls.clear();
    _lives.removeFromParent();
    _starship.removeFromParent();
    field.removeFromParent();
    for (final row in bricks) {
      for (var brick in row) {
        if (brick != null) {
          brick.removeFromParent();
        }
      }
    }
  }

  Ball _newBall() {
    final ball = Ball(rules: definition.rules);
    ball.position = Vector2(
      field.x - ball.width / 2,
      field.lowWall -
          _starshipBottomMargin -
          _starship.height -
          ball.height -
          1,
    );
    return ball;
  }

  Field _newField() => Field(fieldType)
    ..priority = -10
    ..position = Vector2(game.size.x / 2, 0);

  Starship _newStarship() => Starship(
        onPowerUp: _onPowerUpTaken,
        onEscape: _onStarshipEscape,
      );

  EnemyDirector _newEnemyDirector() => EnemyDirector(
        roundNumber: definition.roundNumber,
        field: () => field,
        isPlaying: () => _phase == RoundPhase.playing,
        onEnemyDestroyed: (enemy) {
          addScore(100);
          game.audio.play(GameSound.alienHit);
        },
      );

  void _removeTemporaryComponents() {
    _enemyDirector.reset();
    for (final component in children.toList()) {
      if (component is PowerUp ||
          component is BreakAnimationComponent ||
          component is Laser ||
          component is Enemy ||
          component is EnemyGate) {
        component.removeFromParent();
      }
    }
    _fallingPowerUp = null;
  }

  Future<void> _restartAfterLifeLoss() async {
    _removeTemporaryComponents();
    final previousField = field;
    final previousStarship = _starship;
    previousField.removeFromParent();
    previousStarship.removeFromParent();
    for (final row in bricks) {
      for (final brick in row) {
        brick?.removeFromParent();
      }
    }
    final fieldDelayElapsed = await _waitFor(const Duration(milliseconds: 500));
    if (!fieldDelayElapsed ||
        !_isCurrentRound ||
        _phase != RoundPhase.lifeLost) {
      return;
    }

    field = _newField();
    _starship = _newStarship();
    await add(field);
    await loadBricks();
    await add(_roundNumberComponent
      ..text = 'PLAYER 1\nREADY'
      ..position = Vector2(
        field.x,
        field.y + field.height * 0.75,
      ));
    game.audio.play(GameSound.gameStart);
    final readyDelayElapsed =
        await _waitFor(const Duration(seconds: 1, milliseconds: 500));
    if (!readyDelayElapsed ||
        !_isCurrentRound ||
        _phase != RoundPhase.lifeLost) {
      return;
    }

    _positionStarship();
    final ball = _newBall();
    balls
      ..clear()
      ..add(ball);
    await _mountRoundComponents(ball, addLives: false);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_phase == RoundPhase.playing) {
      final List<Ball> ballsToRemove = [];
      for (var ball in balls) {
        if (ball.y > field.lowWall) {
          ballsToRemove.add(ball);
        }
      }
      for (var element in ballsToRemove) {
        balls.removeAt(balls.indexOf(element));
        element.removeFromParent();
      }
      if (balls.isEmpty) {
        async.unawaited(lifeLost());
      }
    } else if (_phase == RoundPhase.ready && balls.isNotEmpty) {
      balls.first.position.x = _starship.position.x + _starship.size.x / 2;
    }
  }

  void _onBrickDestroyed(
    int rowIndex,
    int columnIndex,
    Brick brick,
  ) {
    if (bricks[rowIndex][columnIndex] != brick) {
      return;
    }

    bricks[rowIndex][columnIndex] = null;
    addScore(brick.value);
    if (brick.model != BrickModel.silver) {
      _spawnCapsule(brick.position);
    }
    final isLevelCompleted = bricks.every((row) => row.every(
          (brick) => brick == null || !brick.canBeBroken,
        ));
    if (isLevelCompleted) {
      levelCompleted();
    }
  }

  void _spawnCapsule(Vector2 position) {
    final breakableBricksRemaining = bricks.fold(
      0,
      (count, row) =>
          count + row.where((brick) => brick?.canBeBroken ?? false).length,
    );
    final type = _powerUpDirector.select(
      activePowerUp: _starship.powerUp,
      hasFallingCapsule: _fallingPowerUp != null,
      hasMultipleBalls: balls.length > 1,
      portalOpen: _starship.canEscape,
      breakableBricksRemaining: breakableBricksRemaining,
      playerAlreadyAwarded: game.session.lifeCapsuleAlreadyAwarded,
    );
    if (type == null) {
      return;
    }

    late final PowerUp powerUp;
    powerUp = PowerUp(
      type,
      onRemoved: (removed) {
        if (identical(_fallingPowerUp, removed)) {
          _fallingPowerUp = null;
        }
      },
    )..position = position.clone();
    _fallingPowerUp = powerUp;
    add(powerUp);
  }

  void levelCompleted() {
    if (_phase != RoundPhase.playing) {
      return;
    }
    _phase = RoundPhase.completed;
    async.unawaited(_completeLevel());
  }

  Future<void> _completeLevel() async {
    await _removeGameComponents();
    if (_isCurrentRound && _phase == RoundPhase.completed) {
      game.levelCompleted(definition.roundNumber);
    }
  }

  Future<void> lifeLost() async {
    if (_phase != RoundPhase.playing) {
      return;
    }

    _phase = RoundPhase.lifeLost;
    game.session.loseLife();
    _lives.removeLife();

    await _starship.destroy();
    if (!_isCurrentRound || _phase != RoundPhase.lifeLost) {
      return;
    }
    if (game.numberOfLives > 0) {
      await _restartAfterLifeLoss();
    } else {
      _gameOver();
    }
  }

  void addLife() {
    game.session.addLife();
    game.audio.play(GameSound.extraLife);
    _lives.addLife(true);
  }

  void _gameOver() {
    _phase = RoundPhase.gameOver;
    add(_gameOverComponent);
    game.audio.play(GameSound.gameOver);
    async.unawaited(_completeGameOver());
  }

  Future<void> _completeGameOver() async {
    final elapsed = await _waitFor(const Duration(seconds: 3));
    if (elapsed && _isCurrentRound && _phase == RoundPhase.gameOver) {
      game.gameOver();
    }
  }

  void addScore(int score) {
    final awardedLives = game.session.addScore(score);
    for (var index = 0; index < awardedLives; index++) {
      game.audio.play(GameSound.extraLife);
      _lives.addLife(true);
    }
    game.hud.updateScores(
      score: game.currentScore,
      topScore: game.topScore,
    );
  }

  void setMovementDirection(int direction) {
    if (_phase == RoundPhase.ready || _phase == RoundPhase.playing) {
      _starship.setMovementDirection(direction);
    }
  }

  void setHorizontalTarget(double centerX) {
    if (_phase == RoundPhase.ready || _phase == RoundPhase.playing) {
      _starship.setHorizontalTarget(centerX);
    }
  }

  void performAction() {
    if (_phase == RoundPhase.ready) {
      _phase = RoundPhase.playing;
      for (final ball in balls) {
        ball.launch();
      }
    } else if (_phase == RoundPhase.playing) {
      _starship.performAction();
    }
  }

  bool get _isCurrentRound => !_removed && game.currentLevel == this;

  Future<bool> _waitFor(Duration duration) {
    final completer = async.Completer<bool>();
    late final async.Timer timer;
    timer = async.Timer(duration, () {
      _pendingRoundDelays.remove(timer);
      if (!completer.isCompleted) {
        completer.complete(!_removed);
      }
    });
    _pendingRoundDelays[timer] = completer;
    return completer.future;
  }
}
