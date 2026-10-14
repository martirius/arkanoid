import 'package:arkanoid/components/enemy.dart';
import 'package:arkanoid/enemy_director.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('arcade enemy sequence alternates gates and cycles all four forms', () {
    final sequence = ArcadeEnemySequence(roundNumber: 1);

    expect(
      [for (var index = 0; index < 4; index++) sequence.next()],
      [
        (gateIndex: 0, type: EnemyType.konerd),
        (gateIndex: 1, type: EnemyType.pyradok),
        (gateIndex: 0, type: EnemyType.triSphere),
        (gateIndex: 1, type: EnemyType.opopo),
      ],
    );
  });

  test('a gate emits one enemy after its opening animation', () {
    var openings = 0;
    final gate = EnemyGate(
      onOpened: () => openings += 1,
      onRemoved: () {},
    );

    gate.update(0.29);
    expect(openings, 0);
    gate.update(0.01);
    gate.update(0.3);
    expect(openings, 1);
  });
}
