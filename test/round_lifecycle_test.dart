import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/level1.dart';
import 'package:arkanoid/components/levels/level2.dart';
import 'package:arkanoid/components/levels/level3.dart';
import 'package:arkanoid/components/levels/level4.dart';
import 'package:arkanoid/components/levels/level5.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestArkanoid extends Arkanoid {
  _TestArkanoid(BaseLevel level) {
    currentLevel = level;
  }

  @override
  Future<void> onLoad() async {
    scaleFactor = 1;
    add(currentLevel);
  }
}

class _TestLevel extends BaseLevel {
  _TestLevel() : super(FieldType.blue, 1);

  @override
  Future<void> onLoad() async {
    bricks = [
      [
        Brick(BrickModel.red, null),
        Brick(BrickModel.blue, null),
        Brick(BrickModel.green, null),
      ],
    ];
    await super.onLoad();
  }
}

void main() {
  test('the ball stays ready until the player acts', () {
    final game = Arkanoid()..scaleFactor = 1;
    game.currentLevel.field = Field(FieldType.blue)
      ..position = Vector2(112, 0)
      ..scale = Vector2.all(1);
    final ball = Ball()
      ..game = game
      ..position = Vector2(100, 100)
      ..velocity = Vector2(130, -130);
    final readyPosition = ball.position.clone();

    ball.update(1 / 60);
    expect(ball.position, readyPosition);

    ball.onActionPressed();
    ball.update(1 / 60);
    expect(ball.position, isNot(readyPosition));
  });

  test('level progression follows the current five-round sequence', () {
    final game = Arkanoid();

    game.levelCompleted(0);
    expect(game.currentLevel, isA<Level1>());
    game.levelCompleted(1);
    expect(game.currentLevel, isA<Level2>());
    game.levelCompleted(2);
    expect(game.currentLevel, isA<Level3>());
    game.levelCompleted(3);
    expect(game.currentLevel, isA<Level4>());
    game.levelCompleted(4);
    expect(game.currentLevel, isA<Level5>());
    game.levelCompleted(5);
    expect(game.currentLevel, isA<Level1>());
  });

  test('level progression preserves the current session', () {
    final game = Arkanoid()
      ..currentScore = 12340
      ..numberOfLives = 2;

    game.levelCompleted(1);

    expect(game.currentLevel, isA<Level2>());
    expect(game.currentScore, 12340);
    expect(game.numberOfLives, 2);
  });

  testWidgets('a life loss preserves bricks destroyed in the current round',
      (tester) async {
    final level = _TestLevel();
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
    level.onButtonPressed();

    final destroyedBrick = level.bricks.first.first!;
    destroyedBrick.hit(false);
    game.update(1 / 120);
    expect(destroyedBrick.parent, isNull);

    expect(level.bricks.first.first, isNull);
    final lifeLoss = level.lifeLost();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await lifeLoss;

    expect(game.numberOfLives, 2);
    expect(level.bricks.first.first, isNull);
    expect(level.children.whereType<Brick>(), hasLength(2));
  });

  testWidgets('multiple brick removals are reconciled by the round',
      (tester) async {
    final level = _TestLevel();
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
    level.onButtonPressed();

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
  });
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
