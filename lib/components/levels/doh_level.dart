import 'dart:async' as async;

import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/doh.dart';
import 'package:arkanoid/components/ending_sequence.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/level_definition.dart';
import 'package:arkanoid/components/lives.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

final dohDefinition = LevelDefinition(
  roundNumber: 33,
  fieldType: FieldType.boss,
  rows: [
    for (var row = 0; row < LevelDefinition.rowCount; row++) emptyBrickRow,
  ],
);

class DohLevel extends BaseLevel {
  DohLevel() : super(dohDefinition);

  static const _readyDuration = Duration(seconds: 2);
  static const _messageFontSize = 10.0;
  static const _starshipBottomMargin = 12.0;

  late Starship _bossStarship;
  late Lives _bossLives;
  late Doh _doh;
  RoundPhase _bossPhase = RoundPhase.intro;
  final Map<async.Timer, async.Completer<bool>> _pendingDelays = {};
  bool _bossRemoved = false;

  @override
  RoundPhase get phase => _bossPhase;

  TextComponent _message(String text) => TextComponent(
        text: text,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontFamily: 'Joystix',
            fontSize: _messageFontSize,
          ),
          textDirection: TextDirection.ltr,
        ),
        anchor: Anchor.center,
        priority: 100,
      )..position = Vector2(field.x, field.y + field.height * 0.75);

  @override
  Future<void> onLoad() async {
    size = game.size;
    field = _newField();
    _bossStarship = _newStarship();
    _bossLives = Lives(game.numberOfLives)
      ..anchor = Anchor.bottomLeft
      ..priority = 20
      ..position = Vector2(field.leftWall, field.lowWall);
    _doh = _newDoh();
    final ball = _newBall();
    balls
      ..clear()
      ..add(ball);

    await add(field);
    await add(_doh);
    await add(_message('ROUND 33\nREADY'));
    game.audio.play(GameSound.dohStart);
    async.unawaited(_completeIntro(ball));
  }

  Field _newField() => Field(FieldType.boss)
    ..priority = -10
    ..position = Vector2(game.size.x / 2, 0);

  Starship _newStarship() => Starship(
        onPowerUp: (PowerUpType _) {},
        onEscape: () {},
      );

  Doh _newDoh() => Doh(
        isPlaying: () => _bossPhase == RoundPhase.playing,
        target: () => _bossStarship.center,
        playArea: () => Rect.fromLTRB(
          field.leftWall,
          field.topWall,
          field.rightWall,
          field.lowWall,
        ),
        onHit: (playAudio) {
          addScore(Doh.scorePerHit);
          if (playAudio) {
            game.audio.play(GameSound.ballHitBlockUnbreakable);
          }
        },
        onProjectileHit: () => async.unawaited(lifeLost()),
        onDefeatStarted: _onDohDefeatStarted,
        onDefeated: _onDohDefeated,
      )..position = Vector2(field.x, field.topWall + 60);

  Ball _newBall() => Ball(rules: definition.rules)
    ..position = Vector2(
      field.x - 2.5,
      field.lowWall - _starshipBottomMargin - _bossStarship.height - 5,
    );

  void _positionStarship() {
    _bossStarship.position = Vector2(
      field.x - _bossStarship.width / 2,
      field.lowWall - _bossStarship.height - _starshipBottomMargin,
    );
  }

  Future<void> _completeIntro(Ball ball) async {
    final elapsed = await _waitFor(_readyDuration);
    if (!elapsed || !_isCurrentBoss || _bossPhase != RoundPhase.intro) {
      return;
    }
    await _mountRoundComponents(ball, addLives: true);
  }

  Future<void> _mountRoundComponents(
    Ball ball, {
    required bool addLives,
  }) async {
    _positionStarship();
    await add(_bossStarship);
    _bossStarship.appear();
    await add(ball);
    if (addLives) {
      await add(_bossLives);
    }
    for (final message in children.whereType<TextComponent>().toList()) {
      message.removeFromParent();
    }
    _bossPhase = RoundPhase.ready;
    ball.ballCanMove = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_bossPhase == RoundPhase.playing) {
      for (final ball
          in balls.where((ball) => ball.y > field.lowWall).toList()) {
        balls.remove(ball);
        ball.removeFromParent();
      }
      if (balls.isEmpty) {
        async.unawaited(lifeLost());
      }
    } else if (_bossPhase == RoundPhase.ready && balls.isNotEmpty) {
      balls.first.position.x =
          _bossStarship.position.x + _bossStarship.size.x / 2;
    }
  }

  void _onDohDefeatStarted() {
    if (_bossPhase != RoundPhase.playing || !_doh.isDefeated) {
      return;
    }
    _bossPhase = RoundPhase.completed;
    _doh.clearProjectiles();
    for (final ball in balls.toList()) {
      ball.removeFromParent();
    }
    balls.clear();
    _bossStarship.setMovementDirection(0);
    game.audio.play(GameSound.dohDeath);
  }

  void _onDohDefeated() {
    if (!_isCurrentBoss || _bossPhase != RoundPhase.completed) {
      return;
    }
    async.unawaited(_showEndingSequence());
  }

  Future<void> _showEndingSequence() async {
    field.removeFromParent();
    _doh.removeFromParent();
    _bossStarship.removeFromParent();
    _bossLives.removeFromParent();
    for (final message in children.whereType<TextComponent>().toList()) {
      message.removeFromParent();
    }
    game.hud.setControlsEnabled(false);
    await add(
      EndingSequence(
        onFinished: () {
          if (_isCurrentBoss && _bossPhase == RoundPhase.completed) {
            game.gameOver();
          }
        },
      ),
    );
  }

  @override
  Future<void> lifeLost() async {
    if (_bossPhase != RoundPhase.playing) {
      return;
    }

    _bossPhase = RoundPhase.lifeLost;
    _doh.clearProjectiles();
    for (final ball in balls.toList()) {
      ball.removeFromParent();
    }
    balls.clear();
    game.session.loseLife();
    _bossLives.removeLife();

    await _bossStarship.destroy();
    if (!_isCurrentBoss || _bossPhase != RoundPhase.lifeLost) {
      return;
    }
    if (game.numberOfLives > 0) {
      await _restartAfterLifeLoss();
    } else {
      _gameOver();
    }
  }

  Future<void> _restartAfterLifeLoss() async {
    field.removeFromParent();
    _bossStarship.removeFromParent();
    _doh.removeFromParent();
    final fieldDelayElapsed = await _waitFor(const Duration(milliseconds: 500));
    if (!fieldDelayElapsed ||
        !_isCurrentBoss ||
        _bossPhase != RoundPhase.lifeLost) {
      return;
    }

    field = _newField();
    _bossStarship = _newStarship();
    _doh = _newDoh();
    await add(field);
    await add(_doh);
    await add(_message('PLAYER 1\nREADY'));
    game.audio.play(GameSound.dohStart);
    final readyDelayElapsed =
        await _waitFor(const Duration(seconds: 1, milliseconds: 500));
    if (!readyDelayElapsed ||
        !_isCurrentBoss ||
        _bossPhase != RoundPhase.lifeLost) {
      return;
    }

    final ball = _newBall();
    balls.add(ball);
    await _mountRoundComponents(ball, addLives: false);
  }

  void _gameOver() {
    _bossPhase = RoundPhase.gameOver;
    add(_message('GAME\nOVER'));
    game.audio.play(GameSound.gameOver);
    async.unawaited(_completeGameOver());
  }

  Future<void> _completeGameOver() async {
    final elapsed = await _waitFor(const Duration(seconds: 3));
    if (elapsed && _isCurrentBoss && _bossPhase == RoundPhase.gameOver) {
      game.gameOver();
    }
  }

  @override
  void addScore(int score) {
    final awardedLives = game.session.addScore(score);
    for (var index = 0; index < awardedLives; index++) {
      game.audio.play(GameSound.extraLife);
      _bossLives.addLife(true);
    }
    game.hud.updateScores(score: game.currentScore, topScore: game.topScore);
  }

  @override
  void addLife() {
    game.session.addLife();
    game.audio.play(GameSound.extraLife);
    _bossLives.addLife(true);
  }

  @override
  void setMovementDirection(int direction) {
    if (_bossPhase == RoundPhase.ready || _bossPhase == RoundPhase.playing) {
      _bossStarship.setMovementDirection(direction);
    }
  }

  @override
  void setHorizontalTarget(double centerX) {
    if (_bossPhase == RoundPhase.ready || _bossPhase == RoundPhase.playing) {
      _bossStarship.setHorizontalTarget(centerX);
    }
  }

  @override
  void performAction() {
    if (_bossPhase == RoundPhase.ready) {
      _bossPhase = RoundPhase.playing;
      for (final ball in balls) {
        ball.launch();
      }
    } else if (_bossPhase == RoundPhase.playing) {
      _bossStarship.performAction();
    }
  }

  bool get _isCurrentBoss => !_bossRemoved && game.currentLevel == this;

  Future<bool> _waitFor(Duration duration) {
    final completer = async.Completer<bool>();
    late final async.Timer timer;
    timer = async.Timer(duration, () {
      _pendingDelays.remove(timer);
      if (!completer.isCompleted) {
        completer.complete(!_bossRemoved);
      }
    });
    _pendingDelays[timer] = completer;
    return completer.future;
  }

  @override
  void onRemove() {
    _bossRemoved = true;
    _doh.clearProjectiles();
    for (final entry in _pendingDelays.entries.toList()) {
      entry.key.cancel();
      if (!entry.value.isCompleted) {
        entry.value.complete(false);
      }
    }
    _pendingDelays.clear();
    super.onRemove();
  }
}
