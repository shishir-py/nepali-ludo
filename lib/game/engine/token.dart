import 'package:hive/hive.dart';

part 'token.g.dart';

/// The state of an individual Ludo token.
///
/// Positions:
///   -1  → in yard (not yet on board)
///   0‑51 → main track (local to the owning player, 0 = their start)
///   52‑56 → home column (52 = first cell, 56 = last)
///   57  → FINISHED (at centre)
@HiveType(typeId: 0)
class Token {
  @HiveField(0)
  final int id; // 0-3 within a player

  @HiveField(1)
  int position; // -1 to 57

  Token({required this.id, this.position = -1});

  bool get isInYard => position == -1;
  bool get isOnBoard => position >= 0 && position <= 51;
  bool get isInHomeColumn => position >= 52 && position <= 56;
  bool get isFinished => position >= 57;
  bool get isActive => !isInYard && !isFinished;

  /// Can this token be moved by [diceValue]?
  /// Returns false for impossible or finish-overshoot cases.
  bool canMove(int diceValue) {
    if (isFinished) return false;
    if (isInYard) return diceValue == 6;

    final newPos = position + diceValue;
    // On main track
    if (position <= 51) {
      if (position + diceValue > 57) return false; // overshoot home
      return true;
    }
    // In home column
    if (position + diceValue > 57) return false; // overshoot centre
    return true;
  }

  Token copyWith({int? position}) {
    return Token(id: id, position: position ?? this.position);
  }

  @override
  String toString() => 'Token($id @ $position)';
}
