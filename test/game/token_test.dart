import 'package:flutter_test/flutter_test.dart';
import 'package:nepali_ludo/game/engine/token.dart';

void main() {
  group('Token', () {
    test('initial state: in yard', () {
      final t = Token(id: 0);
      expect(t.isInYard, isTrue);
      expect(t.isOnBoard, isFalse);
      expect(t.isFinished, isFalse);
      expect(t.position, -1);
    });

    test('can only leave yard on a 6', () {
      final t = Token(id: 0);
      for (int i = 1; i <= 5; i++) {
        expect(t.canMove(i), isFalse,
            reason: 'Should not be able to move on $i');
      }
      expect(t.canMove(6), isTrue);
    });

    test('on board: can move for any dice value within bounds', () {
      final t = Token(id: 0, position: 10);
      for (int i = 1; i <= 6; i++) {
        expect(t.canMove(i), isTrue);
      }
    });

    test('cannot overshoot past finish (position 57)', () {
      // position 53 + dice 5 = 58 > 57, should not move
      final t = Token(id: 0, position: 53);
      expect(t.canMove(5), isFalse);
      expect(t.canMove(4), isTrue); // 53 + 4 = 57 exact finish
    });

    test('finished token cannot move', () {
      final t = Token(id: 0, position: 57);
      expect(t.isFinished, isTrue);
      expect(t.canMove(1), isFalse);
      expect(t.canMove(6), isFalse);
    });

    test('isInHomeColumn for positions 52-56', () {
      for (int i = 52; i <= 56; i++) {
        final t = Token(id: 0, position: i);
        expect(t.isInHomeColumn, isTrue, reason: 'position $i');
      }
      expect(Token(id: 0, position: 51).isInHomeColumn, isFalse);
      expect(Token(id: 0, position: 57).isInHomeColumn, isFalse);
    });

    test('isActive for positions 0-56', () {
      final t = Token(id: 0, position: 0);
      expect(t.isActive, isTrue);
      expect(t.isOnBoard, isTrue);

      final t2 = Token(id: 0, position: 30);
      expect(t2.isActive, isTrue);
    });

    test('copyWith updates position', () {
      final t = Token(id: 0, position: 5);
      final t2 = t.copyWith(position: 15);
      expect(t2.position, 15);
      expect(t2.id, 0);
      expect(t.position, 5); // original unchanged
    });
  });
}
