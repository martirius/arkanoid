import 'package:flutter_test/flutter_test.dart';

import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/doh_level.dart';
import 'package:arkanoid/components/levels/level_catalog.dart';
import 'package:arkanoid/game_session.dart';
import 'package:arkanoid/main.dart';
import 'package:arkanoid/ui/game_overlays.dart';
import 'package:flutter/material.dart';

class _ReadyLevel extends BaseLevel {
  _ReadyLevel() : super(levelCatalog.first);

  @override
  RoundPhase get phase => RoundPhase.ready;

  @override
  void setMovementDirection(int direction) {}
}

void main() {
  test('a game over offers a continue without resetting the session', () {
    final game = Arkanoid(
      session: GameSession(score: 50000, lives: 0, currentRound: 12),
    )..currentLevel = BaseLevel(levelCatalog[11]);

    game.gameOver();

    expect(game.currentScore, 50000);
    expect(game.numberOfLives, 0);
    expect(game.credits, 3);
    expect(game.flowState, GameFlowState.continuePrompt);

    game.continueGame();

    expect(game.currentScore, 50000);
    expect(game.numberOfLives, GameSession.initialLives);
    expect(game.credits, 2);
    expect(game.currentLevel.definition, same(levelCatalog[11]));
    expect(game.flowState, GameFlowState.playing);
  });

  test('starting a new game resets the session and selects round one', () {
    final game = Arkanoid(
      session: GameSession(score: 50000, lives: 1, currentRound: 12),
    );

    game.startNewGame();

    expect(game.currentScore, 0);
    expect(game.numberOfLives, 3);
    expect(game.currentLevel.definition, same(levelCatalog.first));
    expect(game.flowState, GameFlowState.intro);

    game.skipIntro();

    expect(game.flowState, GameFlowState.playing);
  });

  test('pause and resume change both flow and engine state', () {
    final game = Arkanoid()
      ..currentLevel = _ReadyLevel()
      ..flowState = GameFlowState.playing;

    game.pauseGame();
    expect(game.flowState, GameFlowState.paused);
    expect(game.paused, isTrue);

    game.resumeGame();
    expect(game.flowState, GameFlowState.playing);
    expect(game.paused, isFalse);
  });

  test('completing level five advances to level six', () {
    final game = Arkanoid()..currentLevel = BaseLevel(levelCatalog[4]);

    game.levelCompleted(5);

    expect(game.currentLevel.definition, same(levelCatalog[5]));
  });

  test('completing level 32 starts the Doh round', () {
    final lastLevel = BaseLevel(levelCatalog.last);
    final game = Arkanoid()..currentLevel = lastLevel;

    game.levelCompleted(32);

    expect(game.currentLevel, isA<DohLevel>());
    expect(game.currentLevel.definition.roundNumber, 33);
    expect(game.session.currentRound, 33);
  });

  testWidgets('main menu starts a game once', (tester) async {
    var starts = 0;
    var difficulty = GameDifficulty.easy;
    await tester.pumpWidget(
      MaterialApp(
        home: MainMenuOverlay(
          highScore: 50000,
          credits: 3,
          difficulty: difficulty,
          onDifficultyChanged: (value) => difficulty = value,
          onStart: () => starts++,
        ),
      ),
    );

    expect(find.byKey(const Key('main-menu-title')), findsOneWidget);
    expect(find.text('HIGH SCORE\n50000'), findsOneWidget);
    expect(find.text('CREDIT 3'), findsOneWidget);
    expect(find.text('DIFFICULTY'), findsOneWidget);
    await tester.tap(find.byKey(const Key('difficulty-hard')));
    expect(difficulty, GameDifficulty.hard);
    await tester.tap(find.text('START'));
    expect(starts, 1);
  });

  testWidgets('continue consumes the action or expires after nine seconds',
      (tester) async {
    var continues = 0;
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ContinueOverlay(
          credits: 3,
          onContinue: () => continues++,
          onExit: () => exits++,
        ),
      ),
    );

    expect(find.text('TIME  9'), findsOneWidget);
    await tester.tap(find.text('CONTINUE  1 CREDIT'));
    expect(continues, 1);
    expect(exits, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        home: ContinueOverlay(
          credits: 0,
          onContinue: () => continues++,
          onExit: () => exits++,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 9));
    expect(continues, 1);
    expect(exits, 1);
  });

  testWidgets('pause menu resumes or exits once', (tester) async {
    var resumes = 0;
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PauseOverlay(
          onResume: () => resumes++,
          onExit: () => exits++,
        ),
      ),
    );

    await tester.tap(find.text('RESUME'));
    await tester.tap(find.text('EXIT'));
    expect(resumes, 1);
    expect(exits, 1);
  });

  testWidgets('intro can be skipped with a tap', (tester) async {
    var skips = 0;
    await tester.pumpWidget(
      MaterialApp(home: IntroOverlay(onSkip: () => skips++)),
    );

    await tester.tap(find.byType(IntroOverlay));

    expect(skips, 1);
  });
}
