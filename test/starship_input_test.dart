import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/input_controller.dart';
import 'package:arkanoid/components/inputs/pointer_input_surface.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/gestures.dart'
    show
        DragEndDetails,
        DragStartDetails,
        DragUpdateDetails,
        PointerDeviceKind,
        TapDownDetails;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keyboard movement takes priority over absolute pointer movement', () {
    var movementDirection = 0;
    Vector2? target;
    final controller = InputController(
      onMove: (direction) => movementDirection = direction,
      onMoveTo: (position) => target = position,
      onAction: () {},
    );

    controller.moveTo(Vector2(20, 10));
    expect(target, Vector2(20, 10));

    controller.onKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
      ),
      {LogicalKeyboardKey.keyA},
    );
    expect(movementDirection, -1);
    controller.moveTo(Vector2(40, 10));
    expect(target, Vector2(20, 10));

    controller.onKeyEvent(
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
      ),
      {},
    );
    expect(movementDirection, 0);
    controller.moveTo(Vector2(40, 10));
    expect(target, Vector2(40, 10));
  });

  test('action fires once for a physical key press', () {
    var actions = 0;
    final controller = InputController(
      onMove: (_) {},
      onMoveTo: (_) {},
      onAction: () => actions++,
    );

    controller.onKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration.zero,
      ),
      {LogicalKeyboardKey.space},
    );
    controller.onKeyEvent(
      const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration(milliseconds: 10),
      ),
      {LogicalKeyboardKey.space},
    );

    expect(actions, 1);

    controller.onKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration(milliseconds: 20),
      ),
      {LogicalKeyboardKey.enter},
    );
    expect(actions, 2);
  });

  test('primary mouse click performs one action', () {
    var actions = 0;
    final surface = PointerInputSurface(
      onMoveTo: (_) {},
      onTouchMove: (_) {},
      onAction: () => actions++,
      touchControlsEnabled: false,
    );

    surface.onTapDown(
      TapDownEvent(
        1,
        FlameGame(),
        TapDownDetails(kind: PointerDeviceKind.mouse),
      ),
    );

    expect(actions, 1);
  });

  test('disabled mobile controls ignore touch input', () {
    final positions = <double>[];
    var actions = 0;
    final game = FlameGame();
    final surface = PointerInputSurface(
      onMoveTo: (_) {},
      onTouchMove: positions.add,
      onAction: () => actions++,
      touchControlsEnabled: false,
    )..setTouchArea(position: Vector2.zero(), size: Vector2(100, 100));

    surface.onDragStart(
      DragStartEvent(
        1,
        game,
        DragStartDetails(
          globalPosition: const Offset(50, 50),
          kind: PointerDeviceKind.touch,
        ),
      ),
    );
    surface.onTapDown(
      TapDownEvent(
        2,
        game,
        TapDownDetails(
          globalPosition: const Offset(50, 50),
          kind: PointerDeviceKind.touch,
        ),
      ),
    );

    expect(positions, isEmpty);
    expect(actions, 0);
  });

  test('touch drag stays in its control box and ignores extra pointers', () {
    final positions = <double>[];
    final game = FlameGame();
    final surface = PointerInputSurface(
      onMoveTo: (_) {},
      onTouchMove: positions.add,
      onAction: () {},
      touchControlsEnabled: true,
    )..setTouchArea(position: Vector2(100, 0), size: Vector2(100, 100));

    surface.onDragStart(
      DragStartEvent(
        1,
        game,
        DragStartDetails(
          globalPosition: const Offset(40, 20),
          kind: PointerDeviceKind.touch,
        ),
      ),
    );
    surface.onDragStart(
      DragStartEvent(
        2,
        game,
        DragStartDetails(
          globalPosition: const Offset(120, 20),
          kind: PointerDeviceKind.touch,
        ),
      ),
    );
    surface.onDragStart(
      DragStartEvent(
        3,
        game,
        DragStartDetails(
          globalPosition: const Offset(180, 20),
          kind: PointerDeviceKind.touch,
        ),
      ),
    );
    surface.onDragUpdate(
      DragUpdateEvent(
        2,
        game,
        DragUpdateDetails(
          globalPosition: const Offset(140, 20),
          delta: const Offset(5, 0),
          kind: PointerDeviceKind.touch,
        ),
      ),
    );

    expect(positions, [0.2, 0.4]);

    surface.onDragEnd(DragEndEvent(2, DragEndDetails()));
    surface.onDragStart(
      DragStartEvent(
        3,
        game,
        DragStartDetails(
          globalPosition: const Offset(180, 20),
          kind: PointerDeviceKind.touch,
        ),
      ),
    );
    expect(positions.last, 0.8);
  });

  test('starship moves at the configured horizontal speed', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final starship = Starship(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(100, 200);

    starship.setMovementDirection(1);
    starship.update(0.1);

    expect(starship.x, 125);
  });

  test('absolute input places and clamps the starship center', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final starship = Starship(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(100, 200);

    starship.setHorizontalTarget(120);
    starship.update(1 / 60);
    expect(starship.x, 104);
    starship.update(1 / 60);
    expect(starship.x, 104);

    starship.setHorizontalTarget(500);
    starship.update(1 / 60);
    expect(starship.x, 184);
  });

  test('caught ball follows absolute starship movement', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final starship = Starship(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(100, 200)
      ..powerUp = PowerUpType.cattch;
    final ball = Ball()..position = Vector2(110, 196);

    starship.onCollision({Vector2.zero()}, ball);
    starship.setHorizontalTarget(150);
    starship.update(1 / 60);

    expect(starship.x, 134);
    expect(ball.x, 144);
  });

  test('caught ball follows only the starship effective movement', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final starship = Starship(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(184, 200)
      ..powerUp = PowerUpType.cattch;
    final ball = Ball()..position = Vector2(200, 196);

    starship.onCollision({Vector2.zero()}, ball);
    starship.setMovementDirection(1);
    starship.update(1 / 60);

    expect(starship.x, 184);
    expect(ball.x, 200);
  });

  test('catch releases a ball automatically after four seconds', () {
    final game = Arkanoid();
    game.currentLevel.field = Field(FieldType.blue)..position = Vector2(112, 0);
    final starship = Starship(
      onPowerUp: (_) {},
      onEscape: () {},
    )
      ..game = game
      ..position = Vector2(100, 200)
      ..powerUp = PowerUpType.cattch;
    final ball = Ball()
      ..position = Vector2(110, 196)
      ..ballCanMove = true;

    starship.onCollision({Vector2.zero()}, ball);
    expect(ball.ballCanMove, isFalse);

    starship.update(4);
    expect(ball.ballCanMove, isTrue);
  });
}
