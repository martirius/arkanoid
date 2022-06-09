import 'package:arkanoid/components/brick.dart' hide Brick;
import 'package:arkanoid/components/power_up.dart';
import 'package:flutter/material.dart';
import 'package:group_radio_button/group_radio_button.dart';

import 'level_editor.dart';

class BrickDetails extends StatefulWidget {
  final Brick _brick;
  final Function(Brick) _onSettingsSet;
  const BrickDetails(this._brick, this._onSettingsSet, {Key? key})
      : super(key: key);

  @override
  State<BrickDetails> createState() => _BrickDetailsState();
}

class _BrickDetailsState extends State<BrickDetails> {
  BrickModel? brickModel;
  PowerUpType? powerUpType;

  @override
  void initState() {
    super.initState();
    brickModel = widget._brick.model;
    powerUpType = widget._brick.powerUp;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Brick details"),
        const SizedBox(
          height: 16,
        ),
        const Text("Model"),
        RadioGroup<BrickModel?>.builder(
          groupValue: brickModel,
          onChanged: (value) => setState(() {
            brickModel = value;
          }),
          items: const [...BrickModel.values, null],
          itemBuilder: (item) => RadioButtonBuilder(item?.name ?? "null"),
        ),
        const SizedBox(
          height: 16,
        ),
        const Text("Power up"),
        RadioGroup<PowerUpType?>.builder(
          groupValue: powerUpType,
          onChanged: (value) => setState(() {
            powerUpType = value;
          }),
          items: const [...PowerUpType.values, null],
          itemBuilder: (item) => RadioButtonBuilder(item?.name ?? "null"),
        ),
        ElevatedButton(
            onPressed: () {
              widget._onSettingsSet(Brick(brickModel, powerUpType,
                  widget._brick.xIndex, widget._brick.yIndex));
            },
            child: const Text("Set on brick"))
      ],
    );
  }
}
