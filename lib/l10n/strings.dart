/// Centralised string constants — all UI text in one place
/// so English (or any other language) can be added by mapping
/// the same keys.
class S {
  // ─── App ───────────────────────────────────────────────────
  static const appName = 'नेपाली लुडो';
  static const appTagline = 'खेलौँ, रमाऔँ!';
  static const appVersion = 'संस्करण १.०.०';

  // ─── Home screen ───────────────────────────────────────────
  static const newGame = '🎮 नयाँ खेल';
  static const vsComputer = '🤖 कम्प्युटरसँग खेल';
  static const onlineGame = '🌐 अनलाइन खेल';
  static const withFriends = '👥 साथीहरूसँग खेल';
  static const achievements = '🏆 उपलब्धिहरू';
  static const settings = '⚙️ सेटिङ';
  static const statistics = '📊 तथ्याङ्क';
  static const profile = '👤 प्रोफाइल';
  static const continueGame = 'खेल जारी राख्नुहोस्';
  static const savedGame = 'तपाईंको खेल जारी छ';

  // ─── Game setup ────────────────────────────────────────────
  static const gameSetup = 'खेल सेटअप';
  static const playerCount = 'खेलाडी संख्या';
  static const playerName = 'खेलाडीको नाम';
  static const chooseColor = 'रंग छान्नुहोस्';
  static const difficulty = 'कठिनाई';
  static const easy = 'सजिलो';
  static const normal = 'सामान्य';
  static const hard = 'गाह्रो';
  static const startGame = 'खेल सुरु गर्नुहोस्';
  static const aiPlayer = '🤖 लाटो बोट';
  static const humanPlayer = '👤 मान्छे';

  // ─── Game screen ───────────────────────────────────────────
  static const rollDice = 'पासा हाल्नुहोस्';
  static const yourTurn = 'तपाईंको पालो!';
  static const waitTurn = 'पर्खनुस्...';
  static const botTurn = '🤖 लाटो बोटको पालो!';
  static const gameOver = 'खेल सकियो!';
  static const winner = '🏆 विजेता';
  static const playAgain = 'फेरि खेल्नुहोस्';
  static const quitGame = 'बाहिर निस्कनुहोस्';
  static const pauseGame = 'रोक्नुहोस्';
  static const resumeGame = 'जारी राख्नुहोस्';
  static const react = '😊 प्रतिक्रिया';

  // ─── Player colors ─────────────────────────────────────────
  static const red = 'रातो';
  static const green = 'हरियो';
  static const yellow = 'पहेँलो';
  static const blue = 'नीलो';

  // ─── Announcements (Nepali context messages) ───────────────
  static const rollSix = '🎲 छक्का!';
  static const tokenCaptured = '💥 काटियो!';
  static const tokenHome = '🏠 घर पुग्यो!';
  static const congratulations = '🏆 बधाई छ!';
  static const almostWon = '🔥 अब जित्न लाग्यो!';
  static const botCaptured = '🤖 लाटो बोटले काट्यो!';
  static const playerCapturedBot = '😂 लाटो बोटलाई काटियो!';
  static const noMove = 'कुनै चाल छैन! अर्को खेलाडीको पालो।';
  static const threeSixes = 'तीन छक्का! पालो गुम्यो! 😅';
  static const gotSixExtraTurn = '🎲 छक्का पर्यो! फेरि पालो! 🎲';

  // ─── Settings ──────────────────────────────────────────────
  static const soundEffects = 'आवाज प्रभाव';
  static const music = 'संगीत';
  static const vibration = 'कम्पन';
  static const notifications = 'सूचना';
  static const animationQuality = 'एनिमेशन गुणस्तर';
  static const language = 'भाषा';
  static const aiDifficulty = 'AI कठिनाई';
  static const reactionSettings = 'प्रतिक्रिया सेटिङ';
  static const about = 'बारेमा';
  static const privacy = 'गोपनीयता';
  static const volume = 'भोलुम';

  // ─── Statistics ────────────────────────────────────────────
  static const myStats = '📊 मेरो तथ्याङ्क';
  static const gamesPlayed = 'खेल खेलिएको';
  static const gamesWon = 'जित';
  static const gamesLost = 'हार';
  static const winRate = 'जित दर';
  static const tokensCaptured = 'काटिएका token';
  static const sixesRolled = 'छक्का परेका';
  static const bestStreak = 'सर्वोत्तम लगातार जित';
  static const vsAiGames = 'AI विरुद्ध खेल';
  static const vsHumanGames = 'मान्छे विरुद्ध खेल';

  // ─── Achievements ──────────────────────────────────────────
  static const firstWin = 'पहिलो जित';
  static const firstWinDesc = 'पहिलो खेल जितियो';
  static const sixMaster = 'छक्का मास्टर';
  static const sixMasterDesc = '१० वटा छक्का परे';
  static const captureKing = 'काट्ने राजा';
  static const captureKingDesc = '५० वटा token काटियो';
  static const streakWinner = 'लगातार विजेता';
  static const streakWinnerDesc = '५ खेल लगातार जित';
  static const ludoChampion = 'लुडो च्याम्पियन';
  static const ludoChampionDesc = '१०० खेल पूरा';
  static const speedster = 'छिटो खेलाडी';
  static const speedsterDesc = '१० मिनेटमा जित';
  static const allHome = 'सबै घर';
  static const allHomeDesc = 'एक खेलमा सबै token घर पुर्याउनुहोस्';

  // ─── Reactions ─────────────────────────────────────────────
  static const List<String> nepaliReactions = [
    'कति राम्रो खेलेको! 😂',
    'मलाई नमार न! 😭',
    'हाहा! समातें! 😂',
    'अब त गयो! 😎',
    'लौ न यार! 😭',
    'भाग्य नै बलियो रहेछ! 🍀',
    'ओहो! कस्तो पासा! 😱',
    'मलाई छोड न! 🙏',
    'आज त मेरो दिन हो! 🔥',
    'के भयो साथी? 😂',
    'अब मेरो पालो! 😎',
    'वाह! राम्रो चाल! 👏',
    'ए बाबा! 😱',
    'हैन होला! 🤔',
    'लौ मार्‍यो! 💀',
    'जितें! 🎉',
  ];

  static const List<String> defaultEmojis = [
    '😂', '😭', '😎', '😡', '❤️', '🔥', '🙏', '🤣', '😱', '👏', '🎉', '💪',
  ];

  // ─── Online multiplayer ────────────────────────────────────
  static const createRoom = 'कोठा बनाउनुहोस्';
  static const joinRoom = 'कोठामा जोडिनुहोस्';
  static const roomCode = 'कोठा कोड';
  static const shareCode = 'कोड साझा गर्नुहोस्';
  static const waitingForPlayers = 'खेलाडीहरूको प्रतीक्षा...';
  static const playerJoined = 'खेलाडी जोडिए!';
  static const playerLeft = 'खेलाडी छोडे';
  static const reconnecting = 'पुन: जोडिँदै...';
  static const comingSoon = 'छिट्टै आउँदैछ!';

  // ─── General ───────────────────────────────────────────────
  static const ok = 'ठीक छ';
  static const cancel = 'रद्द गर्नुहोस्';
  static const confirm = 'पुष्टि गर्नुहोस्';
  static const back = 'फिर्ता';
  static const save = 'बचत गर्नुहोस्';
  static const loading = 'लोड हुँदैछ...';
  static const error = 'त्रुटि भयो';
  static const yes = 'हो';
  static const no = 'होइन';
  static const on = 'चालू';
  static const off = 'बन्द';
}
