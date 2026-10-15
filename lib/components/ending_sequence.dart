import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/text.dart';

class EndingSequence extends PositionComponent {
  EndingSequence({required this.onFinished})
      : super(size: Vector2(_width, _height), priority: 200);

  static const duration = 15.5;
  static const _width = 224.0;
  static const _height = 240.0;
  static const _charactersPerSecond = 30.0;
  static const _portalStart = 7.3;
  static const _portalEnd = 9.5;
  static const _vausWarpStart = 3.5;
  static const _vausFlightStart = 4.15;
  static const _vausFlightEnd = 8.0;

  static const _pages = <({double start, double end, String text})>[
    (
      start: 0,
      end: 4.5,
      text: 'DIMENSION-CONTROLLING FORT\n'
          '"DOH" HAS NOW BEEN\n'
          'DEMOLISHED, AND TIME\n'
          'STARTED FLOWING REVERSELY.',
    ),
    (
      start: 4.5,
      end: 7.75,
      text: '"VAUS" MANAGED TO ESCAPE\nFROM THE DISTORTED SPACE.',
    ),
    (
      start: 7.75,
      end: 14.75,
      text: 'BUT THE REAL VOYAGE OF\n'
          '"ARKANOID" IN THE GALAXY\n'
          'HAS ONLY STARTED......',
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
    _mothershipFrames = List.generate(20, (index) {
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
    _renderReverseAttack(canvas);
    _renderVaus(canvas);
    _textPaint.render(canvas, textAt(_elapsed), Vector2(8, 4));
  }

  void _renderMothership(Canvas canvas) {
    final frameIndex = mothershipFrameAt(_elapsed);
    _mothershipFrames[frameIndex].render(
      canvas,
      position: Vector2(frameIndex.isOdd ? -4 : 0, 137),
    );
  }

  static int mothershipFrameAt(double seconds) {
    if (seconds < 2) {
      return 6 - math.min(4, (seconds / 0.35).floor());
    }
    if (seconds >= _portalStart && seconds < _portalEnd) {
      final progress = (seconds - _portalStart) / (_portalEnd - _portalStart);
      return 7 + math.min(12, (progress * 13).floor());
    }
    return (seconds / 0.06).floor() % 2;
  }

  void _renderReverseAttack(Canvas canvas) {
    const attackDuration = 2.35;
    if (_elapsed >= attackDuration) {
      return;
    }

    final reversedTime = attackDuration - _elapsed;
    if (reversedTime < 0.57) {
      return;
    }
    final position = switch (reversedTime) {
      < 1.38 => _lerpPosition(
          Vector2(144, 56),
          Vector2(203, 88),
          (reversedTime - 0.57) / (1.38 - 0.57),
        ),
      < 1.86 => _lerpPosition(
          Vector2(203, 88),
          Vector2(124, 109),
          (reversedTime - 1.38) / (1.86 - 1.38),
        ),
      _ => _lerpPosition(
          Vector2(124, 109),
          Vector2(-16, 48),
          (reversedTime - 1.86) / (attackDuration - 1.86),
        ),
    };
    final frameIndex = 15 - math.min(15, (_elapsed / 0.07).floor()).toInt();
    _fighterFrames[frameIndex].render(canvas, position: position);

    if (_elapsed >= 0.71 && _elapsed < 0.97) {
      _laser.render(canvas, position: Vector2(110, 100));
    }
  }

  void _renderVaus(Canvas canvas) {
    final frameIndex = vausFrameAt(_elapsed);
    if (frameIndex == null) {
      return;
    }

    if (_elapsed < _vausFlightStart) {
      _vausFrames[frameIndex].render(
        canvas,
        position: Vector2(64, 112),
      );
      return;
    }

    final progress =
        ((_elapsed - _vausFlightStart) / (_vausFlightEnd - _vausFlightStart))
            .clamp(0.0, 1.0);
    final introProgress = 1 - progress;
    final arc = math.sin(introProgress * math.pi);
    _vausFrames[frameIndex].render(
      canvas,
      position: Vector2(
        90 + 45 * arc - 25 * introProgress,
        145 - 50 * arc - 30 * introProgress,
      ),
    );
  }

  static int? vausFrameAt(double seconds) {
    if (seconds >= _vausWarpStart && seconds < _vausFlightStart) {
      final progress =
          (seconds - _vausWarpStart) / (_vausFlightStart - _vausWarpStart);
      return 17 - math.min(4, (progress * 5).floor()).toInt();
    }
    if (seconds >= _vausFlightStart && seconds < _vausFlightEnd) {
      final progress =
          (seconds - _vausFlightStart) / (_vausFlightEnd - _vausFlightStart);
      return 12 - math.min(12, (progress * 13).floor()).toInt();
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
    return '';
  }

  void finish() {
    if (_finished) {
      return;
    }
    _finished = true;
    onFinished();
  }
}
