import 'package:arkanoid/components/game_hud.dart';
import 'package:arkanoid/components/gameplay_viewport.dart';
import 'package:arkanoid/components/inputs/fire_button.dart';
import 'package:arkanoid/components/inputs/pointer_input_surface.dart';
import 'package:arkanoid/components/top_text.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _HudTestGame extends Arkanoid {
  _HudTestGame({bool touchControlsEnabled = true})
      : super(touchControlsEnabled: touchControlsEnabled);

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
    expect(
      touchSurface.touchAreaSize.x,
      lessThanOrEqualTo(GameHud.maxTouchControlWidth),
    );
  });

  testWidgets('landscape puts controls beside and scores above the playfield',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final game = _HudTestGame();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 1600,
          height: 900,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();

    final viewport = game.camera.viewport;
    final fireButton = game.hud.children.whereType<FireButton>().single;
    final touchSurface =
        game.hud.children.whereType<PointerInputSurface>().single;
    expect(
      touchSurface.touchAreaPosition.x,
      greaterThanOrEqualTo(viewport.position.x + viewport.size.x),
    );
    expect(
      touchSurface.touchAreaSize,
      Vector2(
        GameHud.maxTouchControlWidth,
        GameHud.maxTouchControlHeight,
      ),
    );
    expect(
      touchSurface.touchAreaPosition.y + touchSurface.touchAreaSize.y,
      900 - 24,
    );
    expect(fireButton.position.y + fireButton.size.y, 900 - 24);
    expect(fireButton.center.y, greaterThan(900 / 2));
    for (final score in game.hud.children.whereType<TopText>()) {
      expect(score.position.y, lessThan(viewport.position.y));
      expect(score.position.x, greaterThanOrEqualTo(viewport.position.x));
      expect(
        score.position.x,
        lessThanOrEqualTo(viewport.position.x + viewport.size.x),
      );
    }
  });

  testWidgets('the intro shows scores without showing touch controls',
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

    game.hud.showIntroScoreboard();

    expect(game.hud.isVisible, isTrue);
    expect(game.hud.children.whereType<TopText>(), hasLength(2));
    expect(
      game.hud.children.whereType<FireButton>().single.isVisible,
      isFalse,
    );
    expect(
      game.hud.children.whereType<PointerInputSurface>().single.isVisible,
      isFalse,
    );
  });

  testWidgets('desktop keeps mouse input active without mobile controls',
      (tester) async {
    final game = _HudTestGame(touchControlsEnabled: false);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 800,
          height: 600,
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump();

    game.hud.setGameplayActive(true);

    expect(
      game.hud.children.whereType<FireButton>().single.isVisible,
      isFalse,
    );
    expect(
      game.hud.children.whereType<PointerInputSurface>().single.isVisible,
      isTrue,
    );
    expect(
      game.hud.children
          .whereType<PointerInputSurface>()
          .single
          .touchControlsEnabled,
      isFalse,
    );
  });
}
