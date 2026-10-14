import 'dart:async';
import 'dart:math';

import 'package:arkanoid/components/game_hud.dart';
import 'package:arkanoid/components/gameplay_viewport.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/doh_level.dart';
import 'package:arkanoid/components/levels/level_catalog.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/game_session.dart';
import 'package:flame/camera.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  Flame.device.setPortraitUpOnly();

  final arkanoidGame = Arkanoid();
  runApp(GameWidget(game: arkanoidGame));
}

class Arkanoid extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  Arkanoid({GameSession? session})
      : session = session ?? GameSession(),
        super(camera: _createCamera()) {
    hud = GameHud(
      onMove: (direction) => currentLevel.setMovementDirection(direction),
      onMoveTo: (canvasPosition) => currentLevel.setHorizontalTarget(
        camera.globalToLocal(canvasPosition).x,
      ),
      onAction: () => currentLevel.performAction(),
      score: currentScore,
      topScore: topScore,
    );
  }

  static const double _physicsStep = 1 / 120;
  static const int _maxPhysicsSteps = 8;

  final GameAudio audio = GameAudio();
  final GameSession session;
  late final GameHud hud;
  BaseLevel currentLevel = BaseLevel(levelCatalog.first);

  int get topScore => session.highScore;
  int get currentScore => session.score;
  int get numberOfLives => session.lives;

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    await audio.load();
    add(hud);
    world.add(currentLevel);
  }

  static int physicsStepsFor(double dt) {
    if (dt <= 0) {
      return 0;
    }
    // shortcut: discard stalls beyond 1/15s to avoid a catch-up spiral.
    final simulatedDt = min(dt, _physicsStep * _maxPhysicsSteps);
    return (simulatedDt / _physicsStep).ceil();
  }

  @override
  void update(double dt) {
    final steps = physicsStepsFor(dt);
    if (steps == 0) {
      return;
    }

    final simulatedDt = min(dt, _physicsStep * _maxPhysicsSteps);
    final stepDt = simulatedDt / steps;
    for (var step = 0; step < steps; step++) {
      super.update(stepDt);
    }
  }

  @override
  void onRemove() {
    unawaited(audio.dispose());
    super.onRemove();
  }

  void levelCompleted(int levelNumber) {
    if (levelNumber == levelCatalog.length) {
      if (currentLevel.parent != null) {
        currentLevel.removeFromParent();
      }
      session.currentRound = 33;
      currentLevel = DohLevel();
      world.add(currentLevel);
      return;
    }
    final definition = levelCatalog[levelNumber];
    if (currentLevel.parent != null) {
      currentLevel.removeFromParent();
    }
    session.currentRound = definition.roundNumber;
    currentLevel = BaseLevel(definition);
    world.add(currentLevel);
  }

  void gameOver() {
    session.reset();
    hud.updateScores(score: currentScore, topScore: topScore);
    levelCompleted(0);
  }

  @override
  @mustCallSuper
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);

    // Return handled to prevent macOS noises.
    return KeyEventResult.handled;
  }
}

CameraComponent _createCamera() {
  final camera = CameraComponent(viewport: GameplayViewport())..priority = 0;
  camera.viewfinder.anchor = Anchor.topLeft;
  return camera;
}

Sprite extractSprite(
    double x, double y, double width, double height, String spritesheet) {
  return Sprite(
    Flame.images.fromCache(spritesheet),
    srcPosition: Vector2(x, y),
    srcSize: Vector2(width, height),
  );
}
