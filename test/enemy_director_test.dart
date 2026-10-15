import 'package:arkanoid/components/enemy.dart';
import 'package:arkanoid/enemy_director.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('arcade hard uses one enemy form for the whole round', () {
    expect(const ArcadeEnemyRules(roundNumber: 1).type, EnemyType.konerd);
    expect(const ArcadeEnemyRules(roundNumber: 2).type, EnemyType.pyradok);
    expect(const ArcadeEnemyRules(roundNumber: 3).type, EnemyType.triSphere);
    expect(const ArcadeEnemyRules(roundNumber: 4).type, EnemyType.opopo);
    expect(const ArcadeEnemyRules(roundNumber: 5).type, EnemyType.konerd);
  });

  test('arcade hard opens the gate nearest to Vaus', () {
    const rules = ArcadeEnemyRules(roundNumber: 2);
    expect(
      rules.spawnFor(vausCenterX: 80, fieldCenterX: 112),
      (gateIndex: 0, type: EnemyType.pyradok),
    );
    expect(
      rules.spawnFor(vausCenterX: 150, fieldCenterX: 112),
      (gateIndex: 1, type: EnemyType.pyradok),
    );
  });

  test('a gate emits one enemy after its opening animation', () {
    var openings = 0;
    final gate = EnemyGate(
      onOpened: () => openings += 1,
      onRemoved: () {},
    );

    gate.update(EnemyGate.openingDuration - 0.01);
    expect(openings, 0);
    gate.update(0.01);
    gate.update(EnemyGate.closingDuration);
    expect(openings, 1);
  });
}
