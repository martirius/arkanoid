import 'package:arkanoid/game_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('score awards lives at 20k, 60k and every following 60k', () {
    final session = GameSession();

    expect(session.addScore(19990), 0);
    expect(session.addScore(10), 1);
    expect(session.lives, 4);
    expect(session.nextExtraLifeScore, 60000);

    expect(session.addScore(40000), 1);
    expect(session.nextExtraLifeScore, 120000);
    expect(session.addScore(120000), 2);
    expect(session.lives, 7);
    expect(session.nextExtraLifeScore, 240000);
  });

  test('a life can be added and lost without going below zero', () {
    final session = GameSession();

    session.addLife();
    expect(session.lives, 4);

    for (var index = 0; index < 5; index++) {
      session.loseLife();
    }
    expect(session.lives, 0);
  });

  test('reset starts a new game but preserves the high score', () {
    final session = GameSession(difficulty: GameDifficulty.hard);
    session.addScore(80000);
    session.currentRound = 5;
    session.addLife();
    session.awardLifeCapsule();
    session.useContinue();

    session.reset();

    expect(session.score, 0);
    expect(session.highScore, 80000);
    expect(session.lives, GameSession.initialLives);
    expect(session.credits, GameSession.initialCredits);
    expect(session.currentRound, 1);
    expect(session.nextExtraLifeScore, 20000);
    expect(session.lifeCapsuleAlreadyAwarded, isFalse);
    expect(session.difficulty, GameDifficulty.hard);
  });

  test('difficulty changes enemy pacing without reducing their limit', () {
    expect(GameDifficulty.easy.enemySpawnInterval, 2);
    expect(GameDifficulty.hard.enemySpawnInterval, 0);
  });

  test('a continue consumes one credit and restores the initial lives', () {
    final session = GameSession(lives: 0);

    expect(session.useContinue(), isTrue);
    expect(session.credits, 2);
    expect(session.lives, GameSession.initialLives);

    final noCredits = GameSession(lives: 0, credits: 0);
    expect(noCredits.useContinue(), isFalse);
    expect(noCredits.lives, 0);
  });

  test('the player capsule awards only one life per game', () {
    final session = GameSession();

    expect(session.awardLifeCapsule(), isTrue);
    expect(session.awardLifeCapsule(), isFalse);
    expect(session.lives, GameSession.initialLives + 1);
  });
}
