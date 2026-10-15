import 'package:arkanoid/components/enemy.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _EnemyTestGame extends FlameGame with HasCollisionDetection {}

void main() {
  testWidgets('each enemy uses its complete sprite-sheet layout',
      (tester) async {
    final game = _EnemyTestGame();
    await tester.pumpWidget(
      SizedBox(width: 224, height: 320, child: GameWidget(game: game)),
    );
    await tester.pump();

    final enemies = {
      for (final type in EnemyType.values)
        type: Enemy(
          type: type,
          playArea: () => const Rect.fromLTWH(0, 0, 224, 320),
          onDestroyed: (_) {},
          onRemoved: (_) {},
        )..position = Vector2(40 + type.index * 32, 40),
    };
    game.addAll(enemies.values);
    for (var attempt = 0;
        attempt < 20 && enemies.values.any((enemy) => !enemy.isLoaded);
        attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    const expectedLayouts = {
      EnemyType.konerd: (frames: 8, lastX: 112.0, lastY: 0.0),
      EnemyType.pyradok: (frames: 12, lastX: 80.0, lastY: 16.0),
      EnemyType.triSphere: (frames: 24, lastX: 112.0, lastY: 80.0),
      EnemyType.opopo: (frames: 20, lastX: 0.0, lastY: 112.0),
    };
    for (final MapEntry(key: type, value: expected)
        in expectedLayouts.entries) {
      final frames = enemies[type]!.animations![EnemyState.active]!.frames;
      expect(frames, hasLength(expected.frames), reason: type.name);
      expect(
        frames.last.sprite.srcPosition,
        Vector2(expected.lastX, expected.lastY),
        reason: type.name,
      );
    }

    final explosion =
        enemies.values.first.animations![EnemyState.exploding]!.frames;
    expect(explosion, hasLength(7));
    expect(explosion.first.sprite.srcPosition, Vector2(0, 128));
    expect(explosion.last.sprite.srcPosition, Vector2(80, 128));
    expect(explosion[4].sprite.srcPosition, Vector2(0, 128));

    final first = enemies[EnemyType.konerd]!..position = Vector2(80, 80);
    final second = enemies[EnemyType.pyradok]!..position = Vector2(80, 80);
    first.onCollisionStart(<Vector2>{}, second);
    second.onCollisionStart(<Vector2>{}, first);
    expect(first.position.distanceTo(second.position), 12);

    first.onCollision(<Vector2>{}, second);
    second.onCollision(<Vector2>{}, first);
    expect(first.position.distanceTo(second.position), 12);
  });
}
