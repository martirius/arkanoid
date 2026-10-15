import 'package:arkanoid/components/ending_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ending displays the original arcade text pages', () {
    expect(
      EndingSequence.textAt(4.49),
      'DIMENSION-CONTROLLING FORT\n'
      '"DOH" HAS NOW BEEN\n'
      'DEMOLISHED, AND TIME\n'
      'STARTED FLOWING REVERSELY.',
    );
    expect(
      EndingSequence.textAt(7.74),
      '"VAUS" MANAGED TO ESCAPE\nFROM THE DISTORTED SPACE.',
    );
    expect(
      EndingSequence.textAt(14.74),
      'BUT THE REAL VOYAGE OF\n'
      '"ARKANOID" IN THE GALAXY\n'
      'HAS ONLY STARTED......',
    );
    expect(EndingSequence.textAt(15), isEmpty);
  });

  test('ending uses the return and portal frames without flashing Vaus', () {
    expect(EndingSequence.mothershipFrameAt(0), 6);
    expect(EndingSequence.mothershipFrameAt(1.9), 2);
    expect(EndingSequence.mothershipFrameAt(7.3), 7);
    expect(EndingSequence.mothershipFrameAt(9.49), 19);
    expect(EndingSequence.mothershipFrameAt(10), inInclusiveRange(0, 1));

    expect(EndingSequence.vausFrameAt(3.5), 17);
    expect(EndingSequence.vausFrameAt(4.2), inInclusiveRange(0, 12));
    expect(EndingSequence.vausFrameAt(8), isNull);
    expect(EndingSequence.vausFrameAt(10), isNull);
  });

  test('ending completion callback is emitted once', () {
    var completions = 0;
    final ending = EndingSequence(onFinished: () => completions++);

    ending
      ..update(EndingSequence.duration)
      ..finish();

    expect(completions, 1);
  });
}
