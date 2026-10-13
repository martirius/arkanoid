import 'package:flutter_test/flutter_test.dart';

import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/level_catalog.dart';
import 'package:arkanoid/main.dart';

void main() {
  test('a game over always resets the session and starts level one', () {
    final game = Arkanoid()
      ..currentScore = 50000
      ..numberOfLives = 0;

    game.gameOver();

    expect(game.currentScore, 0);
    expect(game.numberOfLives, 3);
    expect(game.currentLevel.definition, same(levelCatalog.first));
  });

  test('completing level five loops back to a fresh level one', () {
    final game = Arkanoid()..currentLevel = BaseLevel(levelCatalog.last);

    game.levelCompleted(5);

    expect(game.currentLevel.definition, same(levelCatalog.first));
  });
}
