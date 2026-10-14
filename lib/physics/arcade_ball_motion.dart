class ArcadeBallMotion {
  ArcadeBallMotion({required this.speedStage, this.trajectory = 3}) {
    RangeError.checkValueInInterval(speedStage, 0, 15, 'speedStage');
    _checkTrajectory(trajectory);
  }

  static const speedThresholds = [
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    2,
    4,
    8,
    16,
    24,
    31,
  ];

  static const _pixelsPerSecondPerUnit = 130.0;
  static const _paddleTrajectories = [7, 6, 5, 4, 3, 2];
  static const _changedTrajectories = [2, 3, 4, 3, 6, 5, 6, 7];
  static const _positiveDirections = [
    (x: 2.0, y: -1.0),
    (x: 2.0, y: -1.0),
    (x: 1.0, y: -1.0),
    (x: 1.0, y: -2.0),
    (x: -1.0, y: -2.0),
    (x: -1.0, y: -1.0),
    (x: -2.0, y: -1.0),
    (x: -2.0, y: -1.0),
  ];
  static const _speedTable1 = [
    (multiplier: 0, target: 15),
    (multiplier: 0, target: 14),
    (multiplier: 0, target: 13),
    (multiplier: 0, target: 12),
    (multiplier: 1, target: 15),
    (multiplier: 1, target: 14),
    (multiplier: 1, target: 13),
    (multiplier: 1, target: 12),
    (multiplier: 0, target: 4),
    (multiplier: 2, target: 8),
    (multiplier: 0, target: 2),
    (multiplier: 2, target: 4),
    (multiplier: 0, target: 1),
    (multiplier: 2, target: 2),
    (multiplier: 1, target: 1),
    (multiplier: 2, target: 1),
  ];
  static const _speedTable2 = [
    (multiplier: 0, target: 23),
    (multiplier: 0, target: 21),
    (multiplier: 0, target: 20),
    (multiplier: 0, target: 18),
    (multiplier: 1, target: 23),
    (multiplier: 1, target: 21),
    (multiplier: 1, target: 20),
    (multiplier: 1, target: 18),
    (multiplier: 0, target: 6),
    (multiplier: 2, target: 12),
    (multiplier: 0, target: 3),
    (multiplier: 1, target: 4),
    (multiplier: 1, target: 3),
    (multiplier: 1, target: 2),
    (multiplier: 0, target: 1),
    (multiplier: 1, target: 1),
  ];

  int speedStage;
  int speedProgress = 0;
  int trajectory;

  ({double x, double y}) get velocity {
    final absoluteTrajectory = trajectory.abs();
    final direction = _positiveDirections[absoluteTrajectory - 1];
    final speedTable = absoluteTrajectory == 3 || absoluteTrajectory == 6
        ? _speedTable1
        : _speedTable2;
    final speed = speedTable[speedStage];
    final currentScale =
        (speed.multiplier + 1) / speed.target * _pixelsPerSecondPerUnit;
    final nextStage = (speedStage + 1).clamp(0, speedTable.length - 1);
    final nextSpeed = speedTable[nextStage];
    final nextScale =
        (nextSpeed.multiplier + 1) / nextSpeed.target * _pixelsPerSecondPerUnit;
    final transitionProgress =
        speedProgress / (speedThresholds[speedStage] + 1);
    final scale =
        currentScale + (nextScale - currentScale) * transitionProgress;
    final sign = trajectory < 0 ? -1.0 : 1.0;
    return (
      x: direction.x * sign * scale,
      y: direction.y * sign * scale,
    );
  }

  bool registerImpact() {
    speedProgress += 1;
    if (speedProgress <= speedThresholds[speedStage]) {
      return false;
    }

    speedProgress = 0;
    if (speedStage == speedThresholds.length - 1) {
      return false;
    }
    speedStage += 1;
    return true;
  }

  bool slow() {
    speedProgress = 0;
    if (speedStage == 0) {
      return false;
    }
    speedStage -= 1;
    return true;
  }

  void bounceHorizontally() {
    final sign = trajectory.sign;
    trajectory = sign * (9 - trajectory.abs());
  }

  void bounceVertically() {
    trajectory = trajectory > 0 ? trajectory - 9 : trajectory + 9;
  }

  void bounceFromPaddle(double normalizedHitPosition) {
    final zone =
        (normalizedHitPosition.clamp(0.0, 1.0) * _paddleTrajectories.length)
            .floor()
            .clamp(0, _paddleTrajectories.length - 1);
    trajectory = _paddleTrajectories[zone];
  }

  void changeTrajectory() {
    final sign = trajectory.sign;
    trajectory = sign * _changedTrajectories[trajectory.abs() - 1];
  }

  static void _checkTrajectory(int trajectory) {
    if (trajectory == 0 || trajectory.abs() > 8) {
      throw RangeError.range(trajectory, -8, 8, 'trajectory');
    }
  }
}
