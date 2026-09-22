import 'package:flutter_test/flutter_test.dart';
import 'package:nepali_ludo/game/engine/dice.dart';

void main() {
  group('Dice', () {
    late Dice dice;

    setUp(() => dice = Dice());

    test('roll returns value between 1 and 6', () {
      for (int i = 0; i < 100; i++) {
        final value = dice.roll();
        expect(value, greaterThanOrEqualTo(1));
        expect(value, lessThanOrEqualTo(6));
      }
    });

    test('forceValue sets current value', () {
      dice.forceValue(3);
      expect(dice.currentValue, 3);
    });

    test('reset clears value to 0', () {
      dice.roll();
      dice.reset();
      expect(dice.currentValue, 0);
    });

    test('forceValue out of range throws assertion', () {
      expect(() => dice.forceValue(0), throwsAssertionError);
      expect(() => dice.forceValue(7), throwsAssertionError);
    });

    test('all values 1-6 are statistically possible', () {
      final seen = <int>{};
      for (int i = 0; i < 600; i++) {
        seen.add(dice.roll());
        if (seen.length == 6) break;
      }
      expect(seen, containsAll([1, 2, 3, 4, 5, 6]));
    });
  });
}
