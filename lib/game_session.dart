enum GameDifficulty { easy, hard }

class GameSession {
  GameSession({
    this.score = 0,
    int highScore = 50000,
    this.lives = initialLives,
    this.credits = initialCredits,
    this.currentRound = 1,
    this.lifeCapsuleAlreadyAwarded = false,
    this.difficulty = GameDifficulty.easy,
  })  : highScore = score > highScore ? score : highScore,
        nextExtraLifeScore = _nextExtraLifeTarget(score);

  static const int initialLives = 3;
  static const int initialCredits = 3;
  static const int _firstExtraLifeScore = 20000;
  static const int _secondExtraLifeScore = 60000;
  static const int _repeatingExtraLifeStep = 60000;

  int score;
  int highScore;
  int lives;
  int credits;
  int currentRound;
  int nextExtraLifeScore;
  bool lifeCapsuleAlreadyAwarded;
  GameDifficulty difficulty;

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

  bool awardLifeCapsule() {
    if (lifeCapsuleAlreadyAwarded) {
      return false;
    }
    lifeCapsuleAlreadyAwarded = true;
    lives += 1;
    return true;
  }

  int loseLife() {
    if (lives > 0) {
      lives -= 1;
    }
    return lives;
  }

  bool useContinue() {
    if (credits == 0) {
      return false;
    }
    credits -= 1;
    lives = initialLives;
    return true;
  }

  void reset() {
    score = 0;
    lives = initialLives;
    credits = initialCredits;
    currentRound = 1;
    nextExtraLifeScore = _firstExtraLifeScore;
    lifeCapsuleAlreadyAwarded = false;
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
