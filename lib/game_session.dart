class GameSession {
  GameSession({
    this.score = 0,
    int highScore = 50000,
    this.lives = initialLives,
    this.currentRound = 1,
  })  : highScore = score > highScore ? score : highScore,
        nextExtraLifeScore = _nextExtraLifeTarget(score);

  static const int initialLives = 3;
  static const int _firstExtraLifeScore = 20000;
  static const int _secondExtraLifeScore = 60000;
  static const int _repeatingExtraLifeStep = 60000;

  int score;
  int highScore;
  int lives;
  int currentRound;
  int nextExtraLifeScore;

  int addScore(int points) {
    if (points < 0) {
      throw ArgumentError.value(points, 'points', 'Must not be negative');
    }

    score += points;
    if (score > highScore) {
      highScore = score;
    }

    var awardedLives = 0;
    while (score >= nextExtraLifeScore) {
      lives += 1;
      awardedLives += 1;
      nextExtraLifeScore = nextExtraLifeScore == _firstExtraLifeScore
          ? _secondExtraLifeScore
          : nextExtraLifeScore + _repeatingExtraLifeStep;
    }
    return awardedLives;
  }

  void addLife() {
    lives += 1;
  }

  int loseLife() {
    if (lives > 0) {
      lives -= 1;
    }
    return lives;
  }

  void reset() {
    score = 0;
    lives = initialLives;
    currentRound = 1;
    nextExtraLifeScore = _firstExtraLifeScore;
  }

  static int _nextExtraLifeTarget(int score) {
    if (score < _firstExtraLifeScore) {
      return _firstExtraLifeScore;
    }
    if (score < _secondExtraLifeScore) {
      return _secondExtraLifeScore;
    }
    return (score ~/ _repeatingExtraLifeStep + 1) * _repeatingExtraLifeStep;
  }
}
