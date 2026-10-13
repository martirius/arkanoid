import 'package:arkanoid/components/inputs/fire_button.dart';
import 'package:arkanoid/components/inputs/input_controller.dart';
import 'package:arkanoid/components/top_text.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class GameHud extends PositionComponent {
  GameHud({
    required void Function(int direction) onMove,
    required void Function() onAction,
    required int score,
    required int topScore,
  })  : _onMove = onMove,
        _onAction = onAction,
        _score = score,
        _topScore = topScore,
        super(priority: 100);

  final void Function(int direction) _onMove;
  final void Function() _onAction;
  final JoystickComponent _joystick = JoystickComponent(
    knob: Knob(),
    background: Background(),
    margin: const EdgeInsets.only(right: 40, bottom: 40),
    size: 50,
    knobRadius: 20,
  );
  late final FireButton _fireButton;
  late final InputController _inputController;
  late final TopText _playerText;
  late final TopText _topScoreText;
  int _score;
  int _topScore;

  @override
  Future<void> onLoad() async {
    _fireButton = FireButton(Vector2.zero(), onPressed: _onAction);
    _inputController = InputController(
      joystick: _joystick,
      onMove: _onMove,
      onAction: _onAction,
    );
    _playerText = TopText('1UP', _score.toString());
    _topScoreText = TopText('HIGH SCORE', _topScore.toString());
    _layout(findGame()!.canvasSize);

    await addAll([
      _fireButton,
      _joystick,
      _inputController,
      _playerText,
      _topScoreText,
    ]);
    _playerText.blinkLabel();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout(size);
  }

  void _layout(Vector2 canvasSize) {
    size.setFrom(canvasSize);
    if (!isLoading && !isLoaded) {
      return;
    }
    _fireButton.position = Vector2(40, size.y - 40 - _fireButton.size.y);
    _playerText.position = Vector2(size.x / 4, 5);
    _topScoreText.position = Vector2(size.x / 2, 5);
  }

  void updateScores({required int score, required int topScore}) {
    _score = score;
    _topScore = topScore;
    if (isLoaded) {
      _playerText.updateMessage(_score.toString());
      _topScoreText.updateMessage(_topScore.toString());
    }
  }
}
