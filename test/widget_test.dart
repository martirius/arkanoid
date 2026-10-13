import 'package:flutter_test/flutter_test.dart';

import 'package:arkanoid/components/levels/level1.dart';
import 'package:arkanoid/components/levels/level5.dart';
import 'package:arkanoid/main.dart';

void main() {
  test('a game over always resets the session and starts level one', () {
    final game = Arkanoid()
      ..currentScore = 50000
      ..numberOfLives = 0;

    game.gameOver();

    expect(game.currentScore, 0);
    expect(game.numberOfLives, 3);
    expect(game.currentLevel, isA<Level1>());
  });

  test('completing level five loops back to a fresh level one', () {
    final game = Arkanoid()..currentLevel = Level5();

    game.levelCompleted(5);

    expect(game.currentLevel, isA<Level1>());
  });
}
