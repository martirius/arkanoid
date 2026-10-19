import 'package:arkanoid/components/enemy.dart';
import 'package:arkanoid/enemy_director.dart';
import 'package:arkanoid/game_session.dart';
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

  test('easy starts with the MCU slot limit for each round', () {
    expect(
      const ArcadeEnemyRules(roundNumber: 1).slotLimit(
        difficulty: GameDifficulty.easy,
        elapsedSeconds: 0,
      ),
      0,
    );
    expect(
      const ArcadeEnemyRules(roundNumber: 2).slotLimit(
        difficulty: GameDifficulty.easy,
        elapsedSeconds: 0,
      ),
      1,
    );
    expect(
      const ArcadeEnemyRules(roundNumber: 6).slotLimit(
        difficulty: GameDifficulty.easy,
        elapsedSeconds: 0,
      ),
      2,
    );
    expect(
      const ArcadeEnemyRules(roundNumber: 3).slotLimit(
        difficulty: GameDifficulty.easy,
        elapsedSeconds: 0,
      ),
      3,
    );
  });

  test('easy unlocks slots at the three arcade frame thresholds', () {
    const rules = ArcadeEnemyRules(roundNumber: 1);
    const fps = ArcadeEnemyRules.arcadeFramesPerSecond;

    expect(
      rules.slotLimit(
        difficulty: GameDifficulty.easy,
        elapsedSeconds: (0x0700 - 1) / fps,
      ),
      0,
    );
    expect(
      rules.slotLimit(
        difficulty: GameDifficulty.easy,
        elapsedSeconds: 0x0700 / fps,
      ),
      1,
    );
    expect(
      rules.slotLimit(
        difficulty: GameDifficulty.easy,
        elapsedSeconds: 0x0e00 / fps,
      ),
      2,
    );
    expect(
      rules.slotLimit(
        difficulty: GameDifficulty.easy,
        elapsedSeconds: 0x1500 / fps,
      ),
      3,
    );
  });

  test('hard always exposes all three slots except in the boss round', () {
    expect(
      const ArcadeEnemyRules(roundNumber: 1).slotLimit(
        difficulty: GameDifficulty.hard,
        elapsedSeconds: 0,
      ),
      EnemyDirector.maxActiveEnemies,
    );
    expect(
      const ArcadeEnemyRules(roundNumber: 33).slotLimit(
        difficulty: GameDifficulty.hard,
        elapsedSeconds: 100,
      ),
      0,
    );
  });

  test('a life reset preserves the elapsed round time', () {
    final director = EnemyDirector(
      roundNumber: 1,
      field: () => throw StateError('round 1 has no initial enemy slot'),
      vausCenterX: () => 112,
      isPlaying: () => true,
      onEnemyDestroyed: (_) {},
      difficulty: GameDifficulty.easy,
    );

    director.update(10);
    director.reset(preserveRoundTime: true);
    expect(director.roundElapsed, 10);

    director.reset();
    expect(director.roundElapsed, 0);
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
