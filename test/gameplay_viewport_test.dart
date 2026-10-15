import 'package:arkanoid/components/gameplay_viewport.dart';
import 'package:arkanoid/components/inputs/fire_button.dart';
import 'package:arkanoid/components/inputs/pointer_input_surface.dart';
import 'package:arkanoid/components/top_text.dart';
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
    expect(game.camera.viewport.position.y, GameplayViewport.screenTopMargin);
    expect(
      game.camera.viewport.position.y + game.camera.viewport.size.y,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets('portrait puts the touch box beside the fire button',
      (tester) async {
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
    final fireButton = game.hud.children.whereType<FireButton>().single;
    final touchSurface =
        game.hud.children.whereType<PointerInputSurface>().single;
    expect(
      touchSurface.touchAreaPosition.x,
      greaterThan(fireButton.position.x + fireButton.size.x),
    );
    expect(touchSurface.touchAreaPosition.y, fireButton.position.y);
  });

  testWidgets('landscape puts controls beside and scores above the playfield',
      (tester) async {
    final game = _HudTestGame();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 800,
          height: 360,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();

    final viewport = game.camera.viewport;
    final touchSurface =
        game.hud.children.whereType<PointerInputSurface>().single;
    expect(
      touchSurface.touchAreaPosition.x,
      greaterThanOrEqualTo(viewport.position.x + viewport.size.x),
    );
    for (final score in game.hud.children.whereType<TopText>()) {
      expect(score.position.y, lessThan(viewport.position.y));
      expect(score.position.x, greaterThanOrEqualTo(viewport.position.x));
      expect(
        score.position.x,
        lessThanOrEqualTo(viewport.position.x + viewport.size.x),
      );
    }
  });
}
