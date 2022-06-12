import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/levels/base_level.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/level_editor/brick_details.dart';
import 'package:arkanoid/level_editor/level_code_generator.dart';
import 'package:flutter/material.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'dart:html';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  window.document.onContextMenu.listen((evt) => evt.preventDefault());
  runApp(const LevelEditorApp());
}

class LevelEditorApp extends StatelessWidget {
  const LevelEditorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LevelEditor(),
    );
  }
}

class LevelEditor extends StatefulWidget {
  const LevelEditor({Key? key}) : super(key: key);

  @override
  State<LevelEditor> createState() => _LevelEditorState();
}

class _LevelEditorState extends State<LevelEditor> {
  final bricks = List<List<Brick>>.generate(BaseLevel.numberOfRow, (index) {
    return List<Brick>.generate(BaseLevel.numerOfBricEachRow,
        (index2) => Brick(BrickModel.blue, null, index, index2));
  });

  FieldType currentFieldType = FieldType.blue;
  Brick? currentBrick = Brick(null, null, 0, 0);
  int currentLevel = 1;
  bool modificationEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onSecondaryTap: () {
          setState(() {
            modificationEnabled = !modificationEnabled;
          });
        },
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 50,
                ),
                ...bricks.map(
                  (row) {
                    return Row(
                      children: [
                        ...row.map(
                          (col) => BrickWidget(col, (brick) {
                            if (modificationEnabled) {
                              setState(() {
                                bricks[brick.xIndex][brick.yIndex] = Brick(
                                  currentBrick?.model,
                                  currentBrick?.powerUp,
                                  brick.xIndex,
                                  brick.yIndex,
                                );
                              });
                            }
                          }, (brick) {
                            setState(() {
                              bricks[brick.xIndex][brick.yIndex] = Brick(
                                currentBrick?.model,
                                currentBrick?.powerUp,
                                brick.xIndex,
                                brick.yIndex,
                              );
                            });
                          }),
                        )
                      ],
                    );
                  },
                ),
                Expanded(child: Container()),
                ElevatedButton(
                    onPressed: () {
                      _showSettingsModal(
                          context, currentFieldType, currentLevel, (p0, p1) {
                        setState(() {
                          currentFieldType = p0;
                          currentLevel = p1;
                        });
                      });
                    },
                    child: const Text("..."))
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    currentBrick != null
                        ? BrickDetails(currentBrick!, (brick) {
                            setState(() {
                              currentBrick = brick;
                            });
                          })
                        : Container(),
                    Expanded(child: Container()),
                    Padding(
                        padding: const EdgeInsets.only(
                            bottom: 24, left: 24, right: 24),
                        child: ElevatedButton(
                          child: const Text("Generate code"),
                          onPressed: () {
                            LevelCodeGenerator(
                              bricks,
                              currentLevel,
                              currentFieldType,
                            ).generateCode();
                          },
                        ))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context, FieldType currentFiledType,
      int currentLevel, void Function(FieldType, int) onSettingsPressed) {
    showModalBottomSheet(
        context: context,
        builder: (ctx) =>
            SettingsModal(currentFiledType, currentLevel, onSettingsPressed));
  }
}

class SettingsModal extends StatefulWidget {
  final FieldType _currentFieldType;
  final int _currentLevel;
  final void Function(FieldType, int) _onSettingsPressed;
  const SettingsModal(
    this._currentFieldType,
    this._currentLevel,
    this._onSettingsPressed, {
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  FieldType currentFieldType = FieldType.blue;
  late final TextEditingController levelController;

  @override
  void initState() {
    super.initState();
    currentFieldType = widget._currentFieldType;
    levelController =
        TextEditingController(text: widget._currentLevel.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Background"),
                RadioGroup<FieldType>.builder(
                  groupValue: currentFieldType,
                  onChanged: (value) => setState(() {
                    currentFieldType = value!;
                  }),
                  items: FieldType.values,
                  itemBuilder: (item) => RadioButtonBuilder(
                    item.name,
                  ),
                ),
                const SizedBox(
                  height: 32,
                ),
              ],
            ),
          ),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Level number"),
              TextField(
                keyboardType: TextInputType.number,
                controller: levelController,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                  onPressed: () {
                    widget._onSettingsPressed(
                        currentFieldType, int.parse(levelController.text));
                  },
                  child: const Text("Apply"))
            ],
          ))
        ],
      ),
    );
  }
}

class BrickWidget extends StatelessWidget {
  final Brick _brick;
  final Function(Brick) _onHover;
  final Function(Brick) _onPressed;

  const BrickWidget(this._brick, this._onHover, this._onPressed, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = Colors.blue;
    switch (_brick.model) {
      case BrickModel.grey:
        color = const Color(0xfff2f2f2);
        break;
      case BrickModel.orange:
        color = const Color(0xffff9000);
        break;
      case BrickModel.lightBlue:
        color = const Color(0xff00ffff);
        break;
      case BrickModel.green:
        color = const Color(0xff00ff00);
        break;
      case BrickModel.red:
        color = const Color(0xffff0000);
        break;
      case BrickModel.blue:
        color = const Color(0xff0070ff);
        break;
      case BrickModel.pink:
        color = const Color(0xffff00ff);
        break;
      case BrickModel.yellow:
        color = const Color(0xffffff00);
        break;
      case BrickModel.silver:
        color = const Color(0xff9e9e9e);
        break;
      case BrickModel.gold:
        color = const Color(0xffbdaf00);
        break;
      case null:
        color = Colors.transparent;
        break;
    }
    return Container(
      height: 20,
      width: (MediaQuery.of(context).size.width - 300) / 15,
      decoration: BoxDecoration(
          color: color,
          border: _brick.model != null
              ? const Border(
                  bottom: BorderSide(width: 2), right: BorderSide(width: 2))
              : null),
      child: InkWell(
        onTap: () {
          _onPressed(_brick);
        },
        child: Stack(children: [
          MouseRegion(
            onEnter: (event) {
              _onHover(_brick);
            },
          ),
          _brick.powerUp != null ? Text(_brick.powerUp.toString()) : Container()
        ]),
      ),
    );
  }
}

class Brick {
  final BrickModel? model;
  final PowerUpType? powerUp;
  final int xIndex;
  final int yIndex;

  Brick(this.model, this.powerUp, this.xIndex, this.yIndex);
}
