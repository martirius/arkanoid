import 'package:arkanoid/components/levels/arcade_rounds.dart';
import 'package:arkanoid/components/levels/level1.dart';
import 'package:arkanoid/components/levels/level2.dart';
import 'package:arkanoid/components/levels/level3.dart';
import 'package:arkanoid/components/levels/level4.dart';
import 'package:arkanoid/components/levels/level5.dart';
import 'package:arkanoid/components/levels/level_definition.dart';

final List<LevelDefinition> levelCatalog = List.unmodifiable([
  level1,
  level2,
  level3,
  level4,
  level5,
  ...arcadeRounds6To32,
]);
