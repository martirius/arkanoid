import 'package:arkanoid/components/brick.dart';
import 'package:arkanoid/components/field.dart';
import 'package:arkanoid/components/power_up.dart';
import 'package:arkanoid/level_editor/brick_details.dart';
import 'package:flutter/material.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

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
  final bricks = List<List<Brick>>.generate(15, (index) {
    return List<Brick>.generate(
        15, (index2) => Brick(BrickModel.blue, null, index, index2));
  });

  FieldType currentFieldType = FieldType.blue;
  Brick? currentBrick = Brick(null, null, 0, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
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
                          print("$brick");
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
              )
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // const Text("Background"),
                  // RadioGroup<FieldType>.builder(
                  //   groupValue: currentFieldType,
                  //   onChanged: (value) => setState(() {
                  //     currentFieldType = value!;
                  //   }),
                  //   items: FieldType.values,
                  //   itemBuilder: (item) => RadioButtonBuilder(
                  //     item.name,
                  //   ),
                  // ),
                  // const SizedBox(
                  //   height: 32,
                  // ),
                  currentBrick != null
                      ? BrickDetails(currentBrick!, (brick) {
                          setState(() {
                            currentBrick = brick;
                          });
                        })
                      : Container()
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class BrickWidget extends StatelessWidget {
  final Brick _brick;
  final Function(Brick) _onPressed;

  const BrickWidget(this._brick, this._onPressed, {Key? key}) : super(key: key);

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
      child: GestureDetector(
        onTap: () {
          _onPressed(_brick);
        },
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
