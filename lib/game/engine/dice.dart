import 'dart:math';

/// Encapsulates dice rolling logic.
class Dice {
  final Random _random;
  int _currentValue = 1;
  bool _hasRolled = false;

  Dice({Random? random}) : _random = random ?? Random();

  int get currentValue => _currentValue;
  bool get hasRolled => _hasRolled;

  /// Roll the dice and return the result (1-6).
  int roll() {
    _currentValue = _random.nextInt(6) + 1;
    _hasRolled = true;
    return _currentValue;
  }

  void reset() {
    _hasRolled = false;
  }

  /// For testing / replaying a specific game state.
  void forceValue(int value) {
    assert(value >= 1 && value <= 6);
    _currentValue = value;
    _hasRolled = true;
  }
}
