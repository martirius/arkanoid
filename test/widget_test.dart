import 'package:flutter_test/flutter_test.dart';

import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/level_catalog.dart';
import 'package:arkanoid/game_session.dart';
import 'package:arkanoid/main.dart';

void main() {
  test('a game over always resets the session and starts level one', () {
    final game = Arkanoid(
      session: GameSession(score: 50000, lives: 0),
    );

    game.gameOver();

    expect(game.currentScore, 0);
    expect(game.numberOfLives, 3);
    expect(game.currentLevel.definition, same(levelCatalog.first));
  });

  test('completing level five advances to level six', () {
    final game = Arkanoid()..currentLevel = BaseLevel(levelCatalog[4]);

    game.levelCompleted(5);

    expect(game.currentLevel.definition, same(levelCatalog[5]));
  });

  test('completing level 32 does not silently loop to level one', () {
    final lastLevel = BaseLevel(levelCatalog.last);
    final game = Arkanoid()..currentLevel = lastLevel;

    game.levelCompleted(32);

    expect(game.currentLevel, same(lastLevel));
  });
}
