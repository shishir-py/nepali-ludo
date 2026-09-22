import 'dart:math';

/// Encapsulates dice rolling logic.
class Dice {
  final Random _random;

  /// Last rolled value, or 0 when the dice has not been rolled yet.
  int _currentValue = 0;
  bool _hasRolled = false;

  /// Value the *next* roll will produce, set via [forceValue].
  int? _forcedValue;

  Dice({Random? random}) : _random = random ?? Random();

  int get currentValue => _currentValue;
  bool get hasRolled => _hasRolled;

  /// Roll the dice and return the result (1-6).
  ///
  /// If [forceValue] was called since the last roll, that value is used
  /// (and consumed) instead of a random one.
  int roll() {
    _currentValue = _forcedValue ?? _random.nextInt(6) + 1;
    _forcedValue = null;
    _hasRolled = true;
    return _currentValue;
  }

  void reset() {
    _currentValue = 0;
    _hasRolled = false;
    _forcedValue = null;
  }

  /// For testing / replaying a specific game state: pins the next [roll]
  /// to [value].
  void forceValue(int value) {
    assert(value >= 1 && value <= 6);
    _currentValue = value;
    _forcedValue = value;
    _hasRolled = true;
  }
}
