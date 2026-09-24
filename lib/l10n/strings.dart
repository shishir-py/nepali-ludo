/// Centralised string constants — all UI text in one place so another
/// language can be added later by mapping the same keys.
///
/// Labels are plain text: screens add their own icons, so strings must not
/// start with an emoji (that caused doubled icons on the home menu).
class S {
  // ─── App ───────────────────────────────────────────────────
  static const appName = 'Ludo Pro';
  static const appTagline = 'Roll. Race. Win!';
  static const appVersion = 'Version 1.0.0';

  // ─── Home screen ───────────────────────────────────────────
  static const newGame = 'New Game';
  static const vsComputer = 'Play vs Computer';
  static const onlineGame = 'Play Online';
  static const withFriends = 'Play with Friends';
  static const achievements = 'Achievements';
  static const settings = 'Settings';
  static const statistics = 'Statistics';
  static const profile = 'Profile';
  static const continueGame = 'Continue';
  static const savedGame = 'Game in progress';

  // ─── Game setup ────────────────────────────────────────────
  static const gameSetup = 'Game Setup';
  static const playerCount = 'Players';
  static const playerName = 'Player name';
  static const chooseColor = 'Choose colour';
  static const difficulty = 'Difficulty';
  static const easy = 'Easy';
  static const normal = 'Normal';
  static const hard = 'Hard';
  static const startGame = 'Start Game';
  static const aiPlayer = 'Lato Bot';
  static const humanPlayer = 'Human';

  // ─── Game screen ───────────────────────────────────────────
  static const rollDice = 'Roll';
  static const yourTurn = 'Your turn';
  static const waitTurn = 'Wait…';
  static const botTurn = "Bot's turn";
  static const gameOver = 'Game over';
  static const winner = 'Winner';
  static const playAgain = 'Play Again';
  static const quitGame = 'Quit';
  static const pauseGame = 'Pause';
  static const resumeGame = 'Resume';
  static const react = 'React';

  // ─── Player colors ─────────────────────────────────────────
  static const red = 'Red';
  static const green = 'Green';
  static const yellow = 'Yellow';
  static const blue = 'Blue';

  // ─── Announcements ─────────────────────────────────────────
  static const rollSix = 'Six!';
  static const tokenCaptured = 'Captured!';
  static const tokenHome = 'Home!';
  static const congratulations = 'Congratulations!';
  static const almostWon = 'Almost there!';
  static const botCaptured = 'Lato Bot got you!';
  static const playerCapturedBot = 'You got Lato Bot!';
  static const noMove = 'No moves';
  static const threeSixes = 'Three sixes — turn lost';
  static const gotSixExtraTurn = 'Six! Roll again';

  // ─── Settings ──────────────────────────────────────────────
  static const soundEffects = 'Sound effects';
  static const music = 'Music';
  static const vibration = 'Vibration';
  static const notifications = 'Notifications';
  static const animationQuality = 'Animation quality';
  static const language = 'Language';
  static const aiDifficulty = 'AI difficulty';
  static const reactionSettings = 'Reactions';
  static const about = 'About';
  static const privacy = 'Privacy';
  static const volume = 'Volume';

  // ─── Statistics ────────────────────────────────────────────
  static const myStats = 'My Statistics';
  static const gamesPlayed = 'Games played';
  static const gamesWon = 'Wins';
  static const gamesLost = 'Losses';
  static const winRate = 'Win rate';
  static const tokensCaptured = 'Tokens captured';
  static const sixesRolled = 'Sixes rolled';
  static const bestStreak = 'Best win streak';
  static const vsAiGames = 'Games vs AI';
  static const vsHumanGames = 'Games vs humans';

  // ─── Achievements ──────────────────────────────────────────
  static const firstWin = 'First Win';
  static const firstWinDesc = 'Win your first game';
  static const sixMaster = 'Six Master';
  static const sixMasterDesc = 'Roll 10 sixes';
  static const captureKing = 'Capture King';
  static const captureKingDesc = 'Capture 50 tokens';
  static const streakWinner = 'Streak Winner';
  static const streakWinnerDesc = 'Win 5 games in a row';
  static const ludoChampion = 'Ludo Champion';
  static const ludoChampionDesc = 'Finish 100 games';
  static const speedster = 'Speedster';
  static const speedsterDesc = 'Win in under 10 minutes';
  static const allHome = 'All Home';
  static const allHomeDesc = 'Bring every token home in one game';

  // ─── Reactions ─────────────────────────────────────────────
  static const List<String> nepaliReactions = [
    'Nice move! 😂',
    "Don't cut me! 😭",
    'Got you! 😂',
    "You're done now! 😎",
    'Oh come on! 😭',
    'Lucky roll! 🍀',
    'What a dice! 😱',
    'Spare me! 🙏',
    "It's my day! 🔥",
    "What's up, friend? 😂",
    'My turn now! 😎',
    'Great move! 👏',
    'Oh no! 😱',
    'No way! 🤔',
    'Knocked out! 💀',
    'I win! 🎉',
  ];

  static const List<String> defaultEmojis = [
    '😂',
    '😭',
    '😎',
    '😡',
    '❤️',
    '🔥',
    '🙏',
    '🤣',
    '😱',
    '👏',
    '🎉',
    '💪',
  ];

  // ─── Online multiplayer ────────────────────────────────────
  static const createRoom = 'Create room';
  static const joinRoom = 'Join room';
  static const roomCode = 'Room code';
  static const shareCode = 'Share code';
  static const waitingForPlayers = 'Waiting for players…';
  static const playerJoined = 'Player joined';
  static const playerLeft = 'Player left';
  static const reconnecting = 'Reconnecting…';
  static const comingSoon = 'Coming soon!';

  // ─── General ───────────────────────────────────────────────
  static const ok = 'OK';
  static const cancel = 'Cancel';
  static const confirm = 'Confirm';
  static const back = 'Back';
  static const save = 'Save';
  static const loading = 'Loading…';
  static const error = 'Something went wrong';
  static const yes = 'Yes';
  static const no = 'No';
  static const on = 'On';
  static const off = 'Off';
}
