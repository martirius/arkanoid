import 'dart:async';
import 'dart:math';

import 'package:arkanoid/components/game_hud.dart';
import 'package:arkanoid/components/gameplay_viewport.dart';
import 'package:arkanoid/components/intro_sequence.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/doh_level.dart';
import 'package:arkanoid/components/levels/level_catalog.dart';
import 'package:arkanoid/game_audio.dart';
import 'package:arkanoid/game_session.dart';
import 'package:arkanoid/ui/game_overlays.dart';
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
  Flame.device.setOrientations(const []);

  final arkanoidGame = Arkanoid();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: GameWidget<Arkanoid>(
            game: arkanoidGame,
            overlayBuilderMap: {
              Arkanoid.mainMenuOverlay: (context, game) => MainMenuOverlay(
                    highScore: game.topScore,
                    onStart: game.startNewGame,
                  ),
              Arkanoid.pauseOverlay: (context, game) => PauseOverlay(
                    onResume: game.resumeGame,
                    onExit: game.returnToMenu,
                  ),
              Arkanoid.gameplayOverlay: (context, game) => GameplayOverlay(
                    onPause: game.pauseGame,
                  ),
              Arkanoid.introOverlay: (context, game) => IntroOverlay(
                    onSkip: game.skipIntro,
                  ),
            },
          ),
        ),
      ),
    ),
  );
}

enum GameFlowState { menu, intro, playing, paused }

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
  static const mainMenuOverlay = 'mainMenu';
  static const pauseOverlay = 'pause';
  static const gameplayOverlay = 'gameplay';
  static const introOverlay = 'intro';

  final GameAudio audio = GameAudio();
  final GameSession session;
  late final GameHud hud;
  BaseLevel currentLevel = BaseLevel(levelCatalog.first);
  IntroSequence? _introSequence;
  GameFlowState flowState = GameFlowState.menu;

  int get topScore => session.highScore;
  int get currentScore => session.score;
  int get numberOfLives => session.lives;

  @override
  Future<void>? onLoad() async {
    super.onLoad();
    await audio.load();
    await add(hud);
    hud.setGameplayActive(false);
    _showOnlyOverlay(mainMenuOverlay);
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

  void startNewGame() {
    if (paused) {
      resumeEngine();
    }
    if (currentLevel.parent != null) {
      currentLevel.removeFromParent();
    }
    unawaited(audio.stopAll());
    session.reset();
    hud.updateScores(score: currentScore, topScore: topScore);
    currentLevel = BaseLevel(levelCatalog.first);
    _introSequence?.removeFromParent();
    _introSequence = IntroSequence(onFinished: _beginGameplay);
    world.add(_introSequence!);
    flowState = GameFlowState.intro;
    hud.showIntroScoreboard();
    _showOnlyOverlay(introOverlay);
    audio.play(GameSound.intro);
  }

  void skipIntro() {
    if (flowState == GameFlowState.intro) {
      _introSequence?.finish();
    }
  }

  void _beginGameplay() {
    if (flowState != GameFlowState.intro) {
      return;
    }
    _introSequence?.removeFromParent();
    _introSequence = null;
    unawaited(audio.stopAll());
    world.add(currentLevel);
    flowState = GameFlowState.playing;
    hud.setGameplayActive(true);
    _showOnlyOverlay(gameplayOverlay);
  }

  void pauseGame() {
    if (flowState != GameFlowState.playing ||
        (currentLevel.phase != RoundPhase.ready &&
            currentLevel.phase != RoundPhase.playing)) {
      return;
    }
    currentLevel.setMovementDirection(0);
    flowState = GameFlowState.paused;
    hud.setControlsEnabled(false);
    _showOnlyOverlay(pauseOverlay);
    pauseEngine();
    unawaited(audio.pause());
  }

  void resumeGame() {
    if (flowState != GameFlowState.paused) {
      return;
    }
    flowState = GameFlowState.playing;
    hud.setControlsEnabled(true);
    _showOnlyOverlay(gameplayOverlay);
    resumeEngine();
    unawaited(audio.resume());
  }

  void returnToMenu() {
    if (paused) {
      resumeEngine();
    }
    unawaited(audio.stopAll());
    _introSequence?.removeFromParent();
    _introSequence = null;
    if (currentLevel.parent != null) {
      currentLevel.removeFromParent();
    }
    session.reset();
    hud.updateScores(score: currentScore, topScore: topScore);
    hud.setGameplayActive(false);
    flowState = GameFlowState.menu;
    _showOnlyOverlay(mainMenuOverlay);
  }

  void gameOver() {
    returnToMenu();
  }

  void _showOnlyOverlay(String name) {
    if (!overlays.registeredOverlays.contains(name)) {
      return;
    }
    overlays
      ..clear()
      ..add(name);
  }

  @override
  @mustCallSuper
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);

    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      final isAction =
          key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter;
      final isPause =
          key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP;
      if (flowState == GameFlowState.menu && isAction) {
        startNewGame();
      } else if (flowState == GameFlowState.intro && isAction) {
        skipIntro();
      } else if (flowState == GameFlowState.intro && isPause) {
        returnToMenu();
      } else if (flowState == GameFlowState.paused &&
          (isPause || key == LogicalKeyboardKey.enter)) {
        resumeGame();
      } else if (flowState == GameFlowState.playing && isPause) {
        pauseGame();
      }
    }

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
