import 'package:hive/hive.dart';
import 'token.dart';

part 'player.g.dart';

enum PlayerType { human, ai }
enum AiDifficulty { easy, normal, hard }

@HiveType(typeId: 1)
class Player {
  @HiveField(0)
  final int index; // 0=Red, 1=Green, 2=Yellow, 3=Blue

  @HiveField(1)
  String name;

  @HiveField(2)
  PlayerType type;

  @HiveField(3)
  AiDifficulty difficulty;

  @HiveField(4)
  List<Token> tokens;

  @HiveField(5)
  bool hasWon;

  @HiveField(6)
  int finishOrder; // 1st, 2nd, 3rd, 4th to finish

  Player({
    required this.index,
    required this.name,
    this.type = PlayerType.human,
    this.difficulty = AiDifficulty.normal,
    List<Token>? tokens,
    this.hasWon = false,
    this.finishOrder = 0,
  }) : tokens = tokens ??
            List.generate(4, (i) => Token(id: i, position: -1));

  static const List<String> colorNames = ['रातो', 'हरियो', 'पहेँलो', 'नीलो'];
  static const List<String> colorHex = ['#E53935', '#43A047', '#FDD835', '#1E88E5'];

  String get colorName => colorNames[index];

  /// Returns moveable tokens for a given dice value.
  List<Token> moveableTokens(int diceValue) {
    return tokens.where((t) => t.canMove(diceValue)).toList();
  }

  /// Has this player placed all 4 tokens at the centre?
  bool get allTokensFinished => tokens.every((t) => t.isFinished);

  /// Tokens still on board or in home column (not in yard, not finished).
  List<Token> get activeTokens => tokens.where((t) => t.isActive).toList();

  /// Tokens in yard.
  List<Token> get yardTokens => tokens.where((t) => t.isInYard).toList();

  Player copyWith({
    String? name,
    PlayerType? type,
    AiDifficulty? difficulty,
    List<Token>? tokens,
    bool? hasWon,
    int? finishOrder,
  }) {
    return Player(
      index: index,
      name: name ?? this.name,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      tokens: tokens ?? this.tokens.map((t) => Token(id: t.id, position: t.position)).toList(),
      hasWon: hasWon ?? this.hasWon,
      finishOrder: finishOrder ?? this.finishOrder,
    );
  }
}
