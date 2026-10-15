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
}
