import 'package:arkanoid/game_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('game audio uses a bounded and unambiguous player configuration', () {
    expect(GameSound.values.map((sound) => sound.fileName).toSet(),
        hasLength(GameSound.values.length));
    expect(GameSound.values.every((sound) => sound.players > 0), isTrue);
    expect(
      GameSound.values.fold<int>(0, (total, sound) => total + sound.players),
      lessThanOrEqualTo(32),
    );
  });
}
