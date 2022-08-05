import 'package:arkanoid/components/ball.dart';
import 'package:arkanoid/components/break_animation.dart';
import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/inputs/button_interactable.dart';
import 'package:arkanoid/components/inputs/inputs.dart';
import 'package:arkanoid/components/lives.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/components/starship.dart';
import 'package:arkanoid/main.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/painting.dart';

abstract class BaseLevel extends PositionComponent
    with HasGameRef<Arkanoid>
    implements ButtonInteractable {
  BaseLevel(this.fieldType, this._roundNumber);

  final JoystickComponent _joystick = JoystickComponent(
      knob: Knob(),
      background: Background(),
      margin: const EdgeInsets.only(right: 40, bottom: 40),
      size: 50,
      knobRadius: 20);
  final int _roundNumber;
  late FireButton _fireButton;
  late Starship _starship;
  final List<Ball> balls = [];
  List<List<Brick?>> bricks = [];
  late Lives _lives;
  late final Field field;
  late final TextComponent _playerLabel;
  final FieldType fieldType;
  bool _gameStarted = false;
  bool _introFinished = false;
  bool _starshipEscaping = false;
  static const int numerOfBricEachRow = 13;
  static const int numberOfRow = 16;
  late final _scoreComponent = TextComponent(
      text: gameRef.currentScore.toString(),
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontFamily: 'Joystix',
              fontSize: 18),
          textDirection: TextDirection.ltr),
      position: Vector2(70, 40),
      anchor: Anchor.center);
  late final _roundNumberComponent = TextComponent(
      text: "Round $_roundNumber\n Ready",
      textRenderer: TextPaint(
          style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontFamily: 'Joystix',
              fontSize: 18),
          textDirection: TextDirection.ltr),
      anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _initializeComponents();
    await _loadComponents();
  }

  void _onPowerUpTaken(PowerUpType powerUpType) {
    switch (powerUpType) {
      case PowerUpType.break_:
        add(BreakAnimationComponent(gameRef.scaleFactor)
          ..anchor = Anchor.bottomRight
          ..position = Vector2(field.position.x + field.size.x * field.scale.x,
              field.position.y + field.size.y * field.scale.y));
        break;
      case PowerUpType.slow:
        for (var ball in balls) {
          ball.slow();
        }
        break;
      case PowerUpType.disrupt:
        final mainBall = balls.first;
        while (balls.length < 3) {
          final ball = Ball()
            ..ballCanMove = true
            ..position = mainBall.position
            ..velocity = Vector2(
                mainBall.velocity.x * (balls.length == 2 ? 0.9 : 0.8),
                mainBall.velocity.y);
          balls.add(ball);
          add(ball);
        }
        break;
      case PowerUpType.player:
        addLife();
        break;
      default:
        break;
    }
  }

  void _onStarshipEscape() {
    _starshipEscaping = true;
    for (var element in balls) {
      element.ballCanMove = false;
      element.removeFromParent();
    }

    FlameAudio.play("wall_portal_took.wav");
    Future.delayed(const Duration(seconds: 4), () {
      gameRef.currentScore += 10000;
      gameRef.levelCompleted(_roundNumber);
    });
  }

  Future<void> _initializeComponents() async {
    size = gameRef.size;
    _lives = Lives(gameRef.numberOfLives, gameRef.scaleFactor)
      ..anchor = Anchor.bottomLeft
      ..priority = 20;
    _starship = Starship(_joystick, _onPowerUpTaken, _onStarshipEscape);
    _fireButton = FireButton(
      Vector2(40, size.y - 40),
    );
    _fireButton.position.y = size.y - 40 - _fireButton.size.y;
    field = Field(fieldType)..position = Vector2(0, 50);
    _playerLabel = TextComponent(
        text: '1UP',
        textRenderer: TextPaint(
            style: const TextStyle(
              color: Color.fromARGB(255, 255, 0, 0),
              fontFamily: 'Joystix',
              fontSize: 18,
            ),
            textDirection: TextDirection.ltr),
        position: Vector2(50, 10));
  }

  Future<void> _loadComponents() async {
    add(_playerLabel);
    add(_fireButton);
    add(_joystick);
    add(_scoreComponent);
    await _loadGameComponents();
  }

  Future<void> loadBricks() async {
    bricks.forEach(((row) async {
      for (var brick in row) {
        if (brick != null) {
          await add(brick
            ..scale = Vector2(gameRef.scaleFactor, gameRef.scaleFactor)
            ..position = Vector2(
                Field.hitboxSize * field.scale.x +
                    (brick.size.x * brick.scale.x) * row.indexOf(brick),
                70 +
                    brick.size.y * brick.scale.y +
                    (brick.size.y * brick.scale.y) * bricks.indexOf(row)));
        }
      }
    }));
  }

  Future<void> _loadGameComponents() async {
    await FlameAudio.audioCache.load('Game_Start.ogg');
    await add(field);
    _starship.position = Vector2(
      (gameRef.size.x / 2) - _starship.size.x / 2,
      field.size.y * field.scale.y + field.position.y - 30,
    );
    _lives.position = Vector2(
      Field.hitboxSize * gameRef.scaleFactor,
      field.size.y * field.scale.y + field.position.y,
    );
    final ball = Ball();
    ball.position = Vector2(
      (gameRef.size.x / 2) - ball.size.x / 2,
      field.size.y * field.scale.y +
          field.position.y -
          30 -
          _starship.size.y -
          1,
    );
    balls.add(ball);
    if (bricks.isNotEmpty) {
      await loadBricks();
    }
    add(_roundNumberComponent
      ..priority = 20
      ..position = Vector2(
          gameRef.size.x / 2,
          (field.size.y * field.scale.y + field.position.y) / 2 +
              (field.size.y * field.scale.y + field.position.y) / 4));

    FlameAudio.play('Game_Start.ogg');
    // wait for audio to finish to start game
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      add(_starship);
      _starship.appear();
      addAll(balls);
      add(_lives);
      _roundNumberComponent.removeFromParent();
      _fireButton.addInteractable(_starship);
      _fireButton.addInteractable(this);
      _fireButton.addInteractable(balls.first);
      _introFinished = true;
    });
    //score shower component
  }

  Future<void> _removeGameComponents() async {
    for (var element in children) {
      if (element is PowerUp || element is BreakAnimationComponent) {
        element.removeFromParent();
      }
    }
    for (var element in balls) {
      element.removeFromParent();
      _fireButton.removeInteractable(element);
    }
    _lives.removeFromParent();
    _starship.removeFromParent();
    field.removeFromParent();
    _fireButton.removeInteractable(_starship);
    _fireButton.removeInteractable(this);
    bricks.forEach(((row) async {
      for (var brick in row) {
        if (brick != null) {
          brick.removeFromParent();
        }
      }
    }));
  }

  @override
  void onRemove() {
    for (var child in children) {
      child.removeFromParent();
    }
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_introFinished) {
      if (_gameStarted) {
        final List<Ball> ballsToRemove = [];
        for (var ball in balls) {
          if (ball.y > field.size.y * field.scale.y + field.position.y) {
            ballsToRemove.add(ball);
          }
        }
        for (var element in ballsToRemove) {
          balls.removeAt(balls.indexOf(element));
          element.removeFromParent();
        }
        if (balls.isEmpty && !_starshipEscaping) {
          //all balls are gone, life lost
          lifeLost();
        }
        final gameBricks = children.whereType<Brick>();

        //put brick as null if it doesn't exist anymore
        MapEntry<int, int>? brickToRemove;
        bricks.forEach(((row) {
          for (var brick in row) {
            if (!gameBricks.contains(brick) && brick != null) {
              //brick broken, add score
              gameRef.currentScore += brick.value;
              _scoreComponent.text = gameRef.currentScore.toString();
              final rowIdx = bricks.indexOf(row);
              final colIdx = bricks[bricks.indexOf(row)].indexOf(brick);
              brickToRemove = MapEntry(rowIdx, colIdx);
            }
          }
        }));

        if (brickToRemove != null) {
          bricks[brickToRemove!.key][brickToRemove!.value] = null;
        }
        bool levelCompleted = bricks.every((row) => row.where((brick) {
              return brick != null ? brick.canBeBroken : false;
            }).isEmpty);
        if (levelCompleted) {
          //no more brick, level completed
          gameRef.levelCompleted(_roundNumber);
        }
      } else {
        balls.first.position.x = _starship.position.x + _starship.size.x / 2;
      }
    }
  }

  /// This method create a row of bricks of the same type with the same power up
  List<Brick?> createBrickRow(
    int rowNum,
    BrickModel brickModel,
    PowerUpType? powerUpType,
  ) {
    return List.generate(15, (index) {
      final block =
          Brick(brickModel, powerUpType != null ? PowerUp(powerUpType) : null);
      return block
        ..position = Vector2(
            Field.hitboxSize + (block.size.x * block.scale.x) * index,
            70 +
                block.size.y * block.scale.y +
                (block.size.y * block.scale.y) * rowNum);
    });
  }

  void lifeLost() async {
    gameRef.numberOfLives -= 1;
    _lives.removeLife();
    _introFinished = false;
    _gameStarted = false;
    await _starship.destroy();
    await _removeGameComponents();
    await Future.delayed(const Duration(milliseconds: 500));
    if (gameRef.numberOfLives > 0) {
      await _loadGameComponents();
    } else {
      // GAME OVER
      // TODO : handle game over
    }
  }

  void addLife() {
    FlameAudio.play('extra_life.wav');
    gameRef.numberOfLives += 1;
    _lives.addLife(true);
  }

  @override
  void onButtonPressed() {
    if (_introFinished) {
      _gameStarted = true;
    }
  }
}
