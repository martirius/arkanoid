class RoundRules {
  RoundRules(this.roundNumber) {
    RangeError.checkValueInInterval(roundNumber, 1, 32, 'roundNumber');
  }

  final int roundNumber;

  int get silverBrickHits => 2 + (roundNumber - 1) ~/ 8;

  int get silverBrickPoints => 400 + ((roundNumber - 1) ~/ 8) * 200;

  int get initialBallSpeedStage => roundNumber <= 16 ? 12 : 13;
}
