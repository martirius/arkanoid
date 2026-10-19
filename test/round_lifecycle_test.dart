import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/enemy.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/level_catalog.dart';
import 'package:arkanoid/components/levels/level_definition.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/game_session.dart';
import 'package:arkanoid/main.dart';
import 'package:arkanoid/enemy_director.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestArkanoid extends Arkanoid {
  _TestArkanoid(BaseLevel level, {GameSession? session})
      : super(session: session) {
    currentLevel = level;
  }

  @override
  Future<void> onLoad() async {
    add(hud);
    world.add(currentLevel);
  }
}

final _testDefinition = LevelDefinition(
  roundNumber: 1,
  fieldType: FieldType.blue,
  rows: [
    const [
      BrickSpec(BrickModel.red),
      BrickSpec(BrickModel.blue),
      BrickSpec(BrickModel.green),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
    ],
    for (var row = 1; row < LevelDefinition.rowCount; row++) emptyBrickRow,
  ],
);

BaseLevel _testLevel() => BaseLevel(_testDefinition);

void main() {
  test('the ball stays ready until the player acts', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final ball = Ball()
      ..game = game
      ..position = Vector2(100, 100)
      ..velocity = Vector2(130, -130);
    final readyPosition = ball.position.clone();

    ball.update(1 / 60);
    expect(ball.position, readyPosition);

    ball.launch();
    ball.update(1 / 60);
    expect(ball.position, isNot(readyPosition));
  });

  test('level progression follows the arcade round sequence', () {
    final game = Arkanoid();

    game.levelCompleted(0);
    expect(game.currentLevel.definition, same(levelCatalog[0]));
    game.levelCompleted(1);
    expect(game.currentLevel.definition, same(levelCatalog[1]));
    game.levelCompleted(2);
    expect(game.currentLevel.definition, same(levelCatalog[2]));
    game.levelCompleted(3);
    expect(game.currentLevel.definition, same(levelCatalog[3]));
    game.levelCompleted(4);
    expect(game.currentLevel.definition, same(levelCatalog[4]));
    game.levelCompleted(5);
    expect(game.currentLevel.definition, same(levelCatalog[5]));
    game.levelCompleted(31);
    expect(game.currentLevel.definition, same(levelCatalog[31]));
  });

  test('level progression preserves the current session', () {
    final game = Arkanoid(
      session: GameSession(score: 12340, lives: 2),
    );

    game.levelCompleted(1);

    expect(game.currentLevel.definition, same(levelCatalog[1]));
    expect(game.currentScore, 12340);
    expect(game.numberOfLives, 2);
  });

  testWidgets('a life loss preserves bricks destroyed in the current round',
      (tester) async {
    final level = _testLevel();
    final game = _TestArkanoid(level);
    expect(level.phase, RoundPhase.intro);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 224,
          height: 320,
          child: GameWidget(game: game),
        ),
      ),
    );
    await _pumpUntilRoundIsReady(tester, level);
    expect(level.phase, RoundPhase.ready);
    final starship = level.children.whereType<Starship>().single;
    expect(starship.y, level.field.lowWall - starship.height - 12);
    level.performAction();
    expect(level.phase, RoundPhase.playing);
    expect(level.balls.single.ballCanMove, isTrue);

    final destroyedBrick = level.bricks.first.first!;
    destroyedBrick.hit(false);
    game.update(1 / 120);
    expect(destroyedBrick.parent, isNull);

    expect(level.bricks.first.first, isNull);
    final lifeLoss = level.lifeLost();
    expect(level.phase, RoundPhase.lifeLost);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await lifeLoss;

    expect(game.numberOfLives, 2);
    expect(level.phase, RoundPhase.ready);
    expect(level.bricks.first.first, isNull);
    expect(level.children.whereType<Brick>(), hasLength(2));
  });

  testWidgets('multiple removals complete the round and show the next banner',
      (tester) async {
    final level = _testLevel();
    final game = _TestArkanoid(level);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 224,
          height: 320,
          child: GameWidget(game: game),
        ),
      ),
    );
    await _pumpUntilRoundIsReady(tester, level);
    level.performAction();

    final firstBrick = level.bricks.first[0]!;
    final secondBrick = level.bricks.first[1]!;
    firstBrick.hit(false);
    secondBrick.hit(false);
    game.update(1 / 120);

    expect(level.bricks.first[0], isNull);
    expect(level.bricks.first[1], isNull);
    expect(level.bricks.first[2], isNotNull);
    expect(game.currentScore, firstBrick.value + secondBrick.value);
    expect(level.children.whereType<Brick>(), hasLength(1));

    level.bricks.first[2]!.hit(false);
    expect(level.phase, RoundPhase.completed);
    for (var attempt = 0;
        attempt < 20 && game.currentLevel == level;
        attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    final nextLevel = game.currentLevel;
    for (var attempt = 0;
        attempt < 300 &&
            !(nextLevel.isMounted &&
                nextLevel.children.whereType<TextComponent>().any(
                      (component) =>
                          component.isMounted &&
                          _isRoundReadyText(component, 2),
                    ));
        attempt++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(nextLevel.phase, RoundPhase.intro);
    expect(nextLevel.isMounted, isTrue);
    expect(
      nextLevel.children
          .whereType<TextComponent>()
          .where((component) => component.isMounted)
          .where((component) => _isRoundReadyText(component, 2)),
      isNotEmpty,
    );
    await _pumpUntilRoundIsReady(tester, nextLevel);
  });

  testWidgets('escaping is an explicit round phase', (tester) async {
    final level = _testLevel();
    final game = _TestArkanoid(level);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 224,
          height: 320,
          child: GameWidget(game: game),
        ),
      ),
    );
    await _pumpUntilRoundIsReady(tester, level);
    level.performAction();

    final starship = level.children.whereType<Starship>().single;
    starship.onCollision({Vector2.zero()}, PowerUp(PowerUpType.break_));
    starship.state = StarshipState.movingRight;
    starship.onCollision({Vector2.zero()}, level.field);

    expect(level.phase, RoundPhase.escaping);
    level.removeFromParent();
    for (var attempt = 0; attempt < 10 && !level.isRemoved; attempt++) {
      game.update(1 / 120);
      await tester.pump();
    }
    expect(level.isRemoved, isTrue);
  });

  testWidgets('arcade enemies spawn only while the round is playing',
      (tester) async {
    final level = _testLevel();
    final game = _TestArkanoid(level);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 224,
          height: 320,
          child: GameWidget(game: game),
        ),
      ),
    );
    await _pumpUntilRoundIsReady(tester, level);

    for (var step = 0; step < 100; step++) {
      game.update(1 / 15);
    }
    expect(level.children.whereType<Enemy>(), isEmpty);

    level.performAction();
    level.balls.single.ballCanMove = false;
    final director = level.children.whereType<EnemyDirector>().single;
    for (var step = 0;
        step < 800 && director.activeEnemyCount < director.maxActiveEnemies;
        step++) {
      await tester.pump(const Duration(milliseconds: 17));
      if (step % 30 == 0) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
      }
    }

    expect(level.phase, RoundPhase.playing);
    expect(director.activeEnemyCount, director.maxActiveEnemies);
    final enemy = director.activeEnemies.first;
    for (var attempt = 0;
        attempt < 20 && level.children.whereType<Enemy>().isEmpty;
        attempt++) {
      game.update(1 / 60);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(enemy.isLoaded, isTrue);
    expect(enemy.isMounted, isTrue);
    expect(level.children.whereType<Enemy>(), isNotEmpty);

    final scoreBefore = game.currentScore;
    enemy.destroy();
    enemy.destroy();
    expect(game.currentScore, scoreBefore + 100);
  });

  testWidgets('removing a round cancels its pending game-over transition',
      (tester) async {
    final level = _testLevel();
    final game = _TestArkanoid(
      level,
      session: GameSession(lives: 1),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 224,
          height: 320,
          child: GameWidget(game: game),
        ),
      ),
    );
    await _pumpUntilRoundIsReady(tester, level);
    level.performAction();

    final lifeLoss = level.lifeLost();
    expect(level.phase, RoundPhase.lifeLost);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await lifeLoss;
    expect(level.phase, RoundPhase.gameOver);

    final replacement = _testLevel();
    game.currentLevel = replacement;
    level.removeFromParent();
    game.world.add(replacement);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(game.currentLevel, same(replacement));
    expect(game.numberOfLives, 0);
  });
}

bool _isRoundReadyText(TextComponent component, int roundNumber) {
  final normalized =
      component.text.split('\n').map((line) => line.trim()).join('\n');
  return normalized == 'ROUND $roundNumber\nREADY';
}

Future<void> _pumpUntilRoundIsReady(
  WidgetTester tester,
  BaseLevel level,
) async {
  for (var attempt = 0;
      attempt < 30 &&
          (level.balls.isEmpty || level.balls.single.parent != level);
      attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(level.balls, hasLength(1));
  expect(level.balls.single.parent, same(level));
}
