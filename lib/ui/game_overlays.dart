import 'package:flutter/material.dart';

const _orange = Color(0xffff5a1f);

class MainMenuOverlay extends StatelessWidget {
  const MainMenuOverlay({
    required this.highScore,
    required this.onStart,
    super.key,
  });

  final int highScore;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ARKANOID',
                style: TextStyle(
                  color: _orange,
                  fontFamily: 'Joystix',
                  fontSize: 34,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'HIGH SCORE\n$highScore',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Joystix',
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              _MenuButton(label: 'START', onPressed: onStart),
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
    );
  }
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    required this.onResume,
    required this.onExit,
    super.key,
  });

  final VoidCallback onResume;
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
            _MenuButton(label: 'EXIT', onPressed: onExit),
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

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

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
