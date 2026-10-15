import 'dart:math';

import 'package:arkanoid/components/inputs/fire_button.dart';
import 'package:arkanoid/components/inputs/input_controller.dart';
import 'package:arkanoid/components/inputs/pointer_input_surface.dart';
import 'package:arkanoid/components/top_text.dart';
import 'package:flame/components.dart';

class GameHud extends PositionComponent with HasVisibility {
  GameHud({
    required void Function(int direction) onMove,
    required void Function(Vector2 canvasPosition) onMoveTo,
    required void Function() onAction,
    required int score,
    required int topScore,
  })  : _onMove = onMove,
        _onMoveTo = onMoveTo,
        _onAction = onAction,
        _score = score,
        _topScore = topScore,
        super(priority: 100);

  final void Function(int direction) _onMove;
  final void Function(Vector2 canvasPosition) _onMoveTo;
  final void Function() _onAction;
  late final FireButton _fireButton;
  late final PointerInputSurface _pointerInputSurface;
  late final InputController _inputController;
  late final TopText _playerText;
  late final TopText _topScoreText;
  int _score;
  int _topScore;
  bool _gameplayActive = false;
  bool _controlsEnabled = false;
  bool _scoreboardVisible = false;

  static const maxTouchControlWidth = 240.0;
  static const maxTouchControlHeight = 100.0;
  static const _landscapeBottomMargin = 24.0;

  @override
  Future<void> onLoad() async {
    _fireButton = FireButton(Vector2.zero(), onPressed: _performAction);
    _pointerInputSurface = PointerInputSurface(
      onMoveTo: _inputControllerMoveTo,
      onTouchMove: _inputControllerTouchMove,
      onAction: _performAction,
    );
    _inputController = InputController(
      onMove: _move,
      onMoveTo: _onMoveTo,
      onAction: _performAction,
    );
    _playerText = TopText('1UP', _score.toString());
    _topScoreText = TopText('HIGH SCORE', _topScore.toString());
    _layout(findGame()!.canvasSize);

    await addAll([
      _pointerInputSurface,
      _fireButton,
      _inputController,
      _playerText,
      _topScoreText,
    ]);
    _applyGameplayState();
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
    final viewport = findGame()!.camera.viewport;
    final isLandscape = size.x > size.y;
    if (isLandscape) {
      final controlHeight = min(
        maxTouchControlHeight,
        max(0.0, size.y - _landscapeBottomMargin * 2),
      );
      final controlY = max(
        0.0,
        size.y - controlHeight - _landscapeBottomMargin,
      );
      final viewportRight = viewport.position.x + viewport.size.x;
      final rightAreaWidth = max(0.0, size.x - viewportRight);
      final rightMargin = min(24.0, rightAreaWidth / 4);
      final controlWidth = min(
        maxTouchControlWidth,
        max(0.0, rightAreaWidth - rightMargin * 2),
      );
      _fireButton.position = Vector2(
        max(0.0, (viewport.position.x - _fireButton.size.x) / 2),
        max(
          0.0,
          size.y - _fireButton.size.y - _landscapeBottomMargin,
        ),
      );
      _pointerInputSurface.setTouchArea(
        position: Vector2(
          viewportRight + (rightAreaWidth - controlWidth) / 2,
          controlY,
        ),
        size: Vector2(controlWidth, controlHeight),
      );
    } else {
      _fireButton.position = Vector2(
        min(40.0, max(0.0, size.x - _fireButton.size.x)),
        max(0.0, size.y - 40 - _fireButton.size.y),
      );
      final controlX = _fireButton.position.x + _fireButton.size.x + 20;
      _pointerInputSurface.setTouchArea(
        position: Vector2(controlX, _fireButton.position.y),
        size: Vector2(
          min(
            maxTouchControlWidth,
            max(0.0, size.x - controlX - 24),
          ),
          min(maxTouchControlHeight, _fireButton.size.y),
        ),
      );
    }
    _pointerInputSurface.size.setFrom(size);
    _playerText.position = Vector2(
      viewport.position.x + viewport.size.x / 4,
      5,
    );
    _topScoreText.position = Vector2(
      viewport.position.x + viewport.size.x / 2,
      5,
    );
  }

  void _inputControllerMoveTo(Vector2 canvasPosition) {
    if (_controlsEnabled) {
      _inputController.moveTo(canvasPosition);
    }
  }

  void _inputControllerTouchMove(double horizontalPosition) {
    if (_controlsEnabled) {
      final viewport = findGame()!.camera.viewport;
      _inputController.moveTo(
        Vector2(
          viewport.position.x + viewport.size.x * horizontalPosition,
          viewport.position.y,
        ),
      );
    }
  }

  void _move(int direction) {
    if (_controlsEnabled) {
      _onMove(direction);
    }
  }

  void _performAction() {
    if (_controlsEnabled) {
      _onAction();
    }
  }

  void setGameplayActive(bool active) {
    _gameplayActive = active;
    _controlsEnabled = active;
    _scoreboardVisible = active;
    if (!active && isLoaded) {
      _inputController.reset();
    }
    if (isLoaded) {
      _applyGameplayState();
    }
  }

  void showIntroScoreboard() {
    _gameplayActive = false;
    _controlsEnabled = false;
    _scoreboardVisible = true;
    if (isLoaded) {
      _inputController.reset();
      _applyGameplayState();
    }
  }

  void setControlsEnabled(bool enabled) {
    _controlsEnabled = enabled && _gameplayActive;
    if (!enabled && isLoaded) {
      _inputController.reset();
    }
    if (isLoaded) {
      _fireButton.isVisible = _controlsEnabled;
      _pointerInputSurface.isVisible = _controlsEnabled;
    }
  }

  void _applyGameplayState() {
    isVisible = _scoreboardVisible;
    _fireButton.isVisible = _controlsEnabled;
    _pointerInputSurface.isVisible = _controlsEnabled;
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
