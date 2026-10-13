import 'dart:async' as async;

import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/break_animation.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/fire_button.dart';
import 'package:arkanoid/components/inputs/input_controller.dart';
import 'package:arkanoid/components/lives.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/components/top_text.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/main.dart';
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

abstract class BaseLevel extends PositionedEntity with HasGameRef<Arkanoid> {
  BaseLevel(this.fieldType, this._roundNumber);

  final JoystickComponent _joystick = JoystickComponent(
      knob: Knob(),
      background: Background(),
      margin: const EdgeInsets.only(right: 40, bottom: 40),
      size: 50,
      knobRadius: 20);
  final int _roundNumber;
  late FireButton _fireButton;
  late InputController _inputController;
  late Starship _starship;
  final List<Ball> balls = [];
  List<List<Brick?>> bricks = [];
  late Lives _lives;
  late Field field;
  final FieldType fieldType;
  RoundPhase _phase = RoundPhase.intro;
  final Map<async.Timer, async.Completer<bool>> _pendingRoundDelays = {};
  bool _removed = false;

  RoundPhase get phase => _phase;

  static const int numerOfBricEachRow = 13;
  static const int numberOfRow = 16;
  late final _playerTextComponent = TopText(
    '1UP',
    gameRef.currentScore.toString(),
  )..position =
      Vector2(field.x - ((field.size.x * gameRef.scaleFactor) / 4), 5);
  late final _topScoreComponent = TopText(
    'HIGH SCORE',
    gameRef.topScore.toString(),
  )..position = Vector2(
      field.x,
      5,
    );
  late final _roundNumberComponent = TextComponent(
      text: "Round $_roundNumber\n Ready",
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontFamily: 'Joystix',
              fontSize: 18),
          textDirection: TextDirection.ltr),
      anchor: Anchor.center);
  late final _gameOverComponent = TextComponent(
      text: "Game\nOver",
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontFamily: 'Joystix',
              fontSize: 18),
          textDirection: TextDirection.ltr),
      anchor: Anchor.center)
    ..position = Vector2(
      field.x,
      (field.y + field.size.y * field.scale.y) / 2,
    );

  @override
  Future<void> onLoad() async {
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
        add(BreakAnimationComponent(gameRef.scaleFactor)
          ..anchor = Anchor.bottomRight
          ..position = Vector2(
              field.position.x + (field.size.x * field.scale.x) / 2,
              field.position.y + field.size.y * field.scale.y));
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
        addLife();
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

    gameRef.audio.play(GameSound.wallPortalTook);
    async.unawaited(_completeEscape());
  }

  Future<void> _completeEscape() async {
    final elapsed = await _waitFor(const Duration(seconds: 4));
    if (!elapsed || !_isCurrentRound || _phase != RoundPhase.escaping) {
      return;
    }
    _phase = RoundPhase.completed;
    gameRef.currentScore += 10000;
    gameRef.levelCompleted(_roundNumber);
  }

  Future<void> _initializeComponents() async {
    size = gameRef.size;
    _lives = Lives(gameRef.numberOfLives, gameRef.scaleFactor)
      ..anchor = Anchor.bottomLeft
      ..priority = 20;
    _starship = _newStarship();
    _inputController = InputController(
      joystick: _joystick,
      onMove: (direction) => _starship.setMovementDirection(direction),
      onAction: performAction,
    );
    _fireButton = FireButton(
      Vector2(40, size.y - 40),
      onPressed: _inputController.pressAction,
    );
    _fireButton.position.y = size.y - 40 - _fireButton.size.y;
    field = _newField();
  }

  Future<void> _loadComponents() async {
    add(_fireButton);
    add(_joystick);
    add(_inputController);
    add(_playerTextComponent);
    add(_topScoreComponent);
    _playerTextComponent.blinkLabel();
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
            ..scale = Vector2(gameRef.scaleFactor, gameRef.scaleFactor)
            ..position = Vector2(
                field.x -
                    ((field.size.x * field.scale.x) / 2) +
                    Field.hitboxSize * field.scale.x +
                    (brick.size.x * brick.scale.x) * columnIndex,
                70 +
                    brick.size.y * brick.scale.y +
                    (brick.size.y * brick.scale.y) * rowIndex));
        }
      }
    }
  }

  Future<void> _loadGameComponents() async {
    await add(field);
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
      ..priority = 20
      ..position = Vector2(
          field.x,
          (field.size.y * field.scale.y + field.y) / 2 +
              (field.size.y * field.scale.y + field.y) / 4));

    gameRef.audio.play(GameSound.gameStart);
    // wait for audio to finish to start game
    final elapsed =
        await _waitFor(const Duration(seconds: 1, milliseconds: 500));
    if (!elapsed || !_isCurrentRound) {
      return;
    }
    await _mountRoundComponents(ball, addLives: true);
    //score shower component
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
      field.x - _starship.size.x * gameRef.scaleFactor / 2,
      field.size.y * field.scale.y +
          field.position.y -
          _starship.size.y * field.scale.y -
          30,
    );
  }

  void _positionLives() {
    _lives.position = Vector2(
      field.x -
          ((field.size.x * field.scale.x) / 2) +
          Field.hitboxSize * gameRef.scaleFactor,
      field.size.y * field.scale.y + field.position.y,
    );
  }

  Future<void> _removeGameComponents() async {
    for (final element in children.toList()) {
      if (element is PowerUp || element is BreakAnimationComponent) {
        element.removeFromParent();
      }
    }
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
    final ball = Ball();
    ball.position = Vector2(
      field.x - ball.size.x * gameRef.scaleFactor / 2,
      field.size.y * field.scale.y +
          field.position.y -
          30 -
          _starship.size.y * field.scale.y -
          ball.size.y * gameRef.scaleFactor -
          1,
    );
    return ball;
  }

  Field _newField() => Field(fieldType)
    ..priority = -10
    ..position = Vector2(gameRef.size.x / 2, 50);

  Starship _newStarship() => Starship(
        onPowerUp: _onPowerUpTaken,
        onEscape: _onStarshipEscape,
      );

  void _removeTemporaryComponents() {
    for (final component in children.toList()) {
      if (component is PowerUp || component is BreakAnimationComponent) {
        component.removeFromParent();
      }
    }
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
        (field.size.y * field.scale.y + field.y) / 2 +
            (field.size.y * field.scale.y + field.y) / 4,
      ));
    gameRef.audio.play(GameSound.gameStart);
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
        if (ball.y > field.size.y * field.scale.y + field.position.y) {
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
    final isLevelCompleted = bricks.every((row) => row.every(
          (brick) => brick == null || !brick.canBeBroken,
        ));
    if (isLevelCompleted) {
      levelCompleted();
    }
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
      gameRef.levelCompleted(_roundNumber);
    }
  }

  Future<void> lifeLost() async {
    if (_phase != RoundPhase.playing) {
      return;
    }

    _phase = RoundPhase.lifeLost;
    gameRef.numberOfLives -= 1;
    _lives.removeLife();

    await _starship.destroy();
    if (!_isCurrentRound || _phase != RoundPhase.lifeLost) {
      return;
    }
    if (gameRef.numberOfLives > 0) {
      await _restartAfterLifeLoss();
    } else {
      _gameOver();
    }
  }

  void addLife() {
    gameRef.audio.play(GameSound.extraLife);
    gameRef.numberOfLives += 1;
    _lives.addLife(true);
  }

  void _gameOver() {
    _phase = RoundPhase.gameOver;
    add(_gameOverComponent);
    gameRef.audio.play(GameSound.gameOver);
    async.unawaited(_completeGameOver());
  }

  Future<void> _completeGameOver() async {
    final elapsed = await _waitFor(const Duration(seconds: 3));
    if (elapsed && _isCurrentRound && _phase == RoundPhase.gameOver) {
      gameRef.gameOver();
    }
  }

  void addScore(int score) {
    gameRef.currentScore += score;
    if (gameRef.currentScore > gameRef.topScore) {
      gameRef.topScore = gameRef.currentScore;
      _topScoreComponent.updateMessage(gameRef.currentScore.toString());
    }
    _playerTextComponent.updateMessage(gameRef.currentScore.toString());
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

  bool get _isCurrentRound => !_removed && gameRef.currentLevel == this;

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
