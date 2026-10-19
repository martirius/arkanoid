import 'dart:async';

import 'package:arkanoid/game_session.dart';
import 'package:flutter/material.dart';

const _orange = Color(0xffff5a1f);

class MainMenuOverlay extends StatefulWidget {
  const MainMenuOverlay({
    required this.highScore,
    required this.credits,
    required this.difficulty,
    required this.onDifficultyChanged,
    required this.onStart,
    this.canResume = false,
    this.onResume,
    super.key,
  }) : assert(!canResume || onResume != null);

  final int highScore;
  final int credits;
  final GameDifficulty difficulty;
  final ValueChanged<GameDifficulty> onDifficultyChanged;
  final VoidCallback onStart;
  final bool canResume;
  final VoidCallback? onResume;

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay> {
  late GameDifficulty _difficulty = widget.difficulty;

  void _selectDifficulty(GameDifficulty difficulty) {
    if (_difficulty == difficulty) {
      return;
    }
    setState(() => _difficulty = difficulty);
    widget.onDifficultyChanged(difficulty);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    key: Key('main-menu-title'),
                    width: 196,
                    height: 54,
                    child: ClipRect(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/intro.png'),
                            alignment: Alignment.topLeft,
                            fit: BoxFit.none,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'HIGH SCORE\n${widget.highScore}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Joystix',
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'DIFFICULTY',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Joystix',
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final difficulty in GameDifficulty.values) ...[
                        _DifficultyButton(
                          difficulty: difficulty,
                          selected: difficulty == _difficulty,
                          onPressed: () => _selectDifficulty(difficulty),
                        ),
                        if (difficulty != GameDifficulty.values.last)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (widget.canResume) ...[
                    _MenuButton(
                      label: 'RESUME GAME',
                      onPressed: widget.onResume,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MenuButton(
                    label: widget.canResume ? 'NEW GAME' : 'START',
                    onPressed: widget.onStart,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CREDIT ${widget.credits}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Joystix',
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MOUSE / TOUCH / A-D\nCLICK / SPACE / ENTER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'Joystix',
                      fontSize: 8,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({
    required this.difficulty,
    required this.selected,
    required this.onPressed,
  });

  final GameDifficulty difficulty;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: OutlinedButton(
        key: Key('difficulty-${difficulty.name}'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? Colors.black : Colors.white,
          backgroundColor: selected ? _orange : Colors.transparent,
          side: const BorderSide(color: _orange, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(
          difficulty.name.toUpperCase(),
          style: const TextStyle(fontFamily: 'Joystix', fontSize: 9),
        ),
      ),
    );
  }
}

class ContinueOverlay extends StatefulWidget {
  const ContinueOverlay({
    required this.credits,
    required this.onContinue,
    required this.onExit,
    super.key,
  });

  static const countdownSeconds = 9;

  final int credits;
  final VoidCallback onContinue;
  final VoidCallback onExit;

  @override
  State<ContinueOverlay> createState() => _ContinueOverlayState();
}

class _ContinueOverlayState extends State<ContinueOverlay> {
  late int _seconds = ContinueOverlay.countdownSeconds;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds == 1) {
        _finish(widget.onExit);
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish(VoidCallback action) {
    if (_finished) {
      return;
    }
    _finished = true;
    _timer?.cancel();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final hasCredits = widget.credits > 0;
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TO CONTINUE GAME',
                    style: TextStyle(
                      color: _orange,
                      fontFamily: 'Joystix',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    hasCredits
                        ? 'PRESS FIRE OR TAP CONTINUE\nBEFORE TIMER REACHES "0".'
                        : 'NO CREDITS AVAILABLE',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Joystix',
                      fontSize: 9,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'TIME  $_seconds',
                    style: const TextStyle(
                      color: Color(0xffffff00),
                      fontFamily: 'Joystix',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CREDIT ${widget.credits}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Joystix',
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _MenuButton(
                    label: 'CONTINUE  1 CREDIT',
                    onPressed:
                        hasCredits ? () => _finish(widget.onContinue) : null,
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    label: 'END GAME',
                    onPressed: () => _finish(widget.onExit),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    required this.onResume,
    required this.onSuspend,
    required this.onExit,
    super.key,
  });

  final VoidCallback onResume;
  final VoidCallback onSuspend;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSE',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Joystix',
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 32),
            _MenuButton(label: 'RESUME', onPressed: onResume),
            const SizedBox(height: 14),
            _MenuButton(label: 'SUSPEND', onPressed: onSuspend),
            const SizedBox(height: 14),
            _MenuButton(label: 'END GAME', onPressed: onExit),
          ],
        ),
      ),
    );
  }
}

class GameplayOverlay extends StatelessWidget {
  const GameplayOverlay({required this.onPause, super.key});

  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: IconButton(
          tooltip: 'Pause',
          onPressed: onPause,
          color: Colors.white70,
          icon: const Icon(Icons.pause),
        ),
      ),
    );
  }
}

class IntroOverlay extends StatelessWidget {
  const IntroOverlay({required this.onSkip, super.key});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSkip,
      child: const SizedBox.expand(),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: _orange, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'Joystix', fontSize: 12),
        ),
      ),
    );
  }
}
