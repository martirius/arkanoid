import 'package:arkanoid/components/gameplay_viewport.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _HudTestGame extends Arkanoid {
  @override
  Future<void> onLoad() async {
    add(hud);
  }
}

void main() {
  test('the game world always uses the original logical resolution', () {
    final game = Arkanoid();

    game.onGameResize(Vector2(360, 800));
    expect(
      game.size,
      Vector2(
        GameplayViewport.logicalWidth,
        GameplayViewport.logicalHeight,
      ),
    );

    game.onGameResize(Vector2(800, 360));
    expect(
      game.size,
      Vector2(
        GameplayViewport.logicalWidth,
        GameplayViewport.logicalHeight,
      ),
    );
  });

  test('the gameplay viewport keeps HUD space when the screen allows it', () {
    final game = Arkanoid();

    game.onGameResize(Vector2(360, 800));
    expect(game.camera.viewport.position.y, GameplayViewport.screenTopMargin);

    game.onGameResize(Vector2(800, 360));
    expect(game.camera.viewport.position.y, 0);
  });

  testWidgets('the HUD matches the real canvas size', (tester) async {
    final game = _HudTestGame();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 360,
          height: 800,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();

    expect(game.hud.size, game.canvasSize);
  });
}
