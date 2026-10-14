import 'package:arkanoid/components/doh.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/levels/doh_level.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestArkanoid extends Arkanoid {
  _TestArkanoid(DohLevel level) {
    currentLevel = level;
  }

  @override
  Future<void> onLoad() async {
    add(hud);
    world.add(currentLevel);
  }
}

void main() {
  test('Doh is defeated by exactly sixteen hits', () {
    var scoredHits = 0;
    var defeatStarted = 0;
    var defeated = 0;
    final doh = Doh(
      isPlaying: () => true,
      target: Vector2.zero,
      playArea: () => const Rect.fromLTWH(0, 0, 224, 240),
      onHit: (_) => scoredHits += 1,
      onProjectileHit: () {},
      onDefeatStarted: () => defeatStarted += 1,
      onDefeated: () => defeated += 1,
    );

    for (var hit = 0; hit < Doh.maxHits - 1; hit++) {
      doh.hitByLaser();
    }
    expect(doh.hits, Doh.maxHits - 1);
    expect(doh.isDefeated, isFalse);
    expect(defeatStarted, 0);

    doh.hitByLaser();
    doh.hitByLaser();
    expect(doh.hits, Doh.maxHits);
    expect(scoredHits, Doh.maxHits);
    expect(doh.isDefeated, isTrue);
    expect(defeatStarted, 1);

    doh.update(1.2);
    doh.update(1.2);
    expect(defeated, 1);
  });

  test('Doh projectile travels towards its initial target', () {
    var hit = false;
    final projectile = DohProjectile(
      origin: Vector2(100, 80),
      target: Vector2(120, 200),
      playArea: () => const Rect.fromLTWH(0, 0, 224, 240),
      onHit: () => hit = true,
      onRemoved: () {},
    );

    projectile.update(0.5);

    expect(projectile.x, greaterThan(100));
    expect(projectile.y, greaterThan(80));
    expect(hit, isFalse);
  });

  testWidgets('round 33 mounts Doh and reaches the ending after sixteen hits',
      (tester) async {
    final level = DohLevel();
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

    await _pumpUntilBossIsReady(tester, level);

    expect(level.field.fieldType, FieldType.boss);
    expect(level.phase, RoundPhase.ready);
    level.performAction();
    expect(level.phase, RoundPhase.playing);

    final doh = level.children.whereType<Doh>().single;
    for (var hit = 0; hit < Doh.maxHits; hit++) {
      doh.hitByLaser();
    }
    expect(level.phase, RoundPhase.completed);
    expect(game.currentScore, Doh.maxHits * Doh.scorePerHit);

    doh.update(1.2);
    game.update(1 / 120);
    await tester.pump();
    expect(
      level.children.whereType<TextComponent>().map((text) => text.text),
      contains('CONGRATULATIONS\nGAME OVER'),
    );
    level.removeFromParent();
    game.update(1 / 120);
    await tester.pump();
  });

  testWidgets('losing a life resets Doh damage', (tester) async {
    final level = DohLevel();
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
    await _pumpUntilBossIsReady(tester, level);
    level.performAction();

    final firstDoh = level.children.whereType<Doh>().single;
    for (var hit = 0; hit < 5; hit++) {
      firstDoh.hitByLaser();
    }
    final lifeLoss = level.lifeLost();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await lifeLoss;

    final restartedDoh = level.children.whereType<Doh>().single;
    expect(restartedDoh, isNot(same(firstDoh)));
    expect(restartedDoh.hits, 0);
    expect(level.phase, RoundPhase.ready);
    expect(game.numberOfLives, 2);

    level.removeFromParent();
    game.update(1 / 120);
    await tester.pump();
  });
}

Future<void> _pumpUntilBossIsReady(
  WidgetTester tester,
  DohLevel level,
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
