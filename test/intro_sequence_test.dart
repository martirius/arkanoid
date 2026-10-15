import 'package:arkanoid/components/intro_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('intro displays the three original arcade text pages', () {
    expect(
      IntroSequence.textAt(1.49),
      'THE ERA AND TIME OF\nTHIS STORY IS UNKNOWN.',
    );
    expect(
      IntroSequence.textAt(4.99),
      'AFTER THE MOTHERSHIP\n'
      '"ARKANOID" WAS DESTROYED,\n'
      'A SPACECRAFT "VAUS"\n'
      'SCRAMBLED AWAY FROM IT.',
    );
    expect(
      IntroSequence.textAt(7.49),
      'BUT ONLY TO BE\n'
      'TRAPPED IN SPACE WARPED\n'
      'BY SOMEONE........',
    );
  });

  test('intro completion callback is emitted once', () {
    var completions = 0;
    final intro = IntroSequence(onFinished: () => completions++);

    intro
      ..update(IntroSequence.duration)
      ..finish();

    expect(completions, 1);
  });

  test('intro only uses the arcade mothership and Vaus frames', () {
    expect(IntroSequence.mothershipFrameAt(0), 0);
    expect(IntroSequence.mothershipFrameAt(0.06), 1);
    expect(IntroSequence.mothershipFrameAt(0.12), 0);
    expect(IntroSequence.mothershipFrameAt(1.42), 2);
    expect(IntroSequence.mothershipFrameAt(1.61), 3);
    expect(IntroSequence.mothershipFrameAt(6), inInclusiveRange(2, 6));

    expect(IntroSequence.vausFrameAt(5.46), inInclusiveRange(13, 17));
    expect(IntroSequence.vausFrameAt(5.47), isNull);
    expect(IntroSequence.vausFrameAt(7), isNull);
  });
}
