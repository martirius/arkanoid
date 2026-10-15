import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/text.dart';

class IntroSequence extends PositionComponent {
  IntroSequence({required this.onFinished})
      : super(size: Vector2(_width, _height));

  static const duration = 7.5;
  static const _width = 224.0;
  static const _height = 240.0;
  static const _charactersPerSecond = 30.0;
  static const _fighterStart = 0.57;
  static const _laserStart = 1.38;
  static const _impactStart = 1.42;
  static const _vausStart = 1.89;
  static const _vausShrinkEnd = 4.04;
  static const _warpStart = 4.82;
  static const _warpEnd = 5.47;

  static const _pages = <({double start, double end, String text})>[
    (
      start: 0,
      end: 1.5,
      text: 'THE ERA AND TIME OF\nTHIS STORY IS UNKNOWN.',
    ),
    (
      start: 1.5,
      end: 5,
      text: 'AFTER THE MOTHERSHIP\n'
          '"ARKANOID" WAS DESTROYED,\n'
          'A SPACECRAFT "VAUS"\n'
          'SCRAMBLED AWAY FROM IT.',
    ),
    (
      start: 5,
      end: duration,
      text: 'BUT ONLY TO BE\n'
          'TRAPPED IN SPACE WARPED\n'
          'BY SOMEONE........',
    ),
  ];

  final void Function() onFinished;
  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      color: Color(0xffffffff),
      fontFamily: 'Joystix',
      fontSize: 8,
      height: 2,
    ),
  );

  late final Sprite _starfield;
  late final List<Sprite> _mothershipFrames;
  late final List<Sprite> _fighterFrames;
  late final Sprite _laser;
  late final List<Sprite> _vausFrames;
  double _elapsed = 0;
  bool _finished = false;

  @override
  Future<void> onLoad() async {
    await Flame.images.loadAll(const [
      'intro_starfield.png',
      'intro.png',
      'intro_fighter.png',
      'intro_laser.png',
      'intro_vaus_escape.png',
    ]);

    _starfield = Sprite(
      Flame.images.fromCache('intro_starfield.png'),
      srcPosition: Vector2(0, 16),
      srcSize: Vector2(_width, _height),
    );
    _mothershipFrames = List.generate(7, (index) {
      return Sprite(
        Flame.images.fromCache('intro.png'),
        srcPosition: Vector2(
          (index % 2) * 196,
          54 + (index ~/ 2) * 100,
        ),
        srcSize: Vector2(196, 83),
      );
    });
    _fighterFrames = _horizontalFrames(
      imageName: 'intro_fighter.png',
      frameWidth: 16,
      count: 16,
    );
    _laser = Sprite(Flame.images.fromCache('intro_laser.png'));
    _vausFrames = _horizontalFrames(
      imageName: 'intro_vaus_escape.png',
      frameWidth: 32,
      count: 19,
    );
  }

  static List<Sprite> _horizontalFrames({
    required String imageName,
    required double frameWidth,
    required int count,
  }) {
    final image = Flame.images.fromCache(imageName);
    return List.generate(
      count,
      (index) => Sprite(
        image,
        srcPosition: Vector2(index * frameWidth, 0),
        srcSize: Vector2(frameWidth, image.height.toDouble()),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished) {
      return;
    }

    _elapsed += dt;
    if (_elapsed >= duration) {
      finish();
    }
  }

  @override
  void render(Canvas canvas) {
    _starfield.render(canvas, size: size);
    _renderMothership(canvas);
    _renderFighter(canvas);
    _renderLaser(canvas);
    _renderVaus(canvas);
    _textPaint.render(canvas, textAt(_elapsed), Vector2(8, 4));
  }

  void _renderMothership(Canvas canvas) {
    _mothershipFrames[mothershipFrameAt(_elapsed)].render(
      canvas,
      position: Vector2(0, 137),
    );
  }

  static int mothershipFrameAt(double seconds) {
    return seconds < _impactStart
        ? (seconds / 0.06).floor() % 2
        : 2 + ((seconds - _impactStart) / 0.18).floor() % 5;
  }

  void _renderFighter(Canvas canvas) {
    const fighterEnd = 2.35;
    if (_elapsed < _fighterStart || _elapsed >= fighterEnd) {
      return;
    }

    final position = switch (_elapsed) {
      < _laserStart => _lerpPosition(
          Vector2(144, 56),
          Vector2(203, 88),
          (_elapsed - _fighterStart) / (_laserStart - _fighterStart),
        ),
      < 1.86 => _lerpPosition(
          Vector2(203, 88),
          Vector2(124, 109),
          (_elapsed - _laserStart) / (1.86 - _laserStart),
        ),
      _ => _lerpPosition(
          Vector2(124, 109),
          Vector2(-16, 48),
          (_elapsed - 1.86) / (fighterEnd - 1.86),
        ),
    };
    final frameIndex = ((_elapsed - _fighterStart) / 0.07).floor() % 16;
    _fighterFrames[frameIndex].render(canvas, position: position);
  }

  void _renderLaser(Canvas canvas) {
    if (_elapsed >= _laserStart && _elapsed < 1.64) {
      _laser.render(canvas, position: Vector2(110, 100));
    }
  }

  void _renderVaus(Canvas canvas) {
    final frameIndex = vausFrameAt(_elapsed);
    if (frameIndex == null) {
      return;
    }

    if (frameIndex <= 12) {
      final progress = ((_elapsed - _vausStart) / (_vausShrinkEnd - _vausStart))
          .clamp(0.0, 1.0);
      final arc = math.sin(progress * math.pi);
      final position = Vector2(
        90 + 45 * arc - 25 * progress,
        145 - 50 * arc - 30 * progress,
      );
      _vausFrames[frameIndex].render(canvas, position: position);
      return;
    }

    _vausFrames[frameIndex].render(
      canvas,
      position: Vector2(64, 112),
    );
  }

  static int? vausFrameAt(double seconds) {
    if (seconds >= _vausStart && seconds < _vausShrinkEnd) {
      final progress = (seconds - _vausStart) / (_vausShrinkEnd - _vausStart);
      return math.min(12, (progress * 13).floor());
    }
    if (seconds >= _warpStart && seconds < _warpEnd) {
      final progress = (seconds - _warpStart) / (_warpEnd - _warpStart);
      return 13 + math.min(4, (progress * 5).floor()).toInt();
    }
    return null;
  }

  static Vector2 _lerpPosition(Vector2 from, Vector2 to, double progress) {
    return from + (to - from) * progress.clamp(0.0, 1.0);
  }

  static String textAt(double seconds) {
    for (final page in _pages) {
      if (seconds >= page.start && seconds < page.end) {
        final visibleCharacters =
            ((seconds - page.start) * _charactersPerSecond)
                .floor()
                .clamp(0, page.text.length);
        return page.text.substring(0, visibleCharacters);
      }
    }
    return _pages.last.text;
  }

  void finish() {
    if (_finished) {
      return;
    }
    _finished = true;
    onFinished();
  }
}
