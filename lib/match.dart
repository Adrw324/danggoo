import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'global.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/foundation.dart';
import 'services/web_socket_service.dart';
import 'playerSelection.dart';
import 'fullscreen.dart';
import 'video-manager.dart';

class MatchScreen extends StatefulWidget {
  GamePlayer player1;
  GamePlayer player2;
  final WebSocketService webSocketService;

  MatchScreen({
    required this.player1,
    required this.player2,
    required this.webSocketService,
  });
  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late Timer _timer;
  bool isTimerRunning = false;
  bool isGameStarted = false;
  int timerSeconds = 0;
  String formattedTime = '00:00:00';
  List<int> buttonCounts = [0, 0];
  DateTime gameStartTime = DateTime.now();
  bool isAnyButtonOn = false;
  int currentPlayer = 0;
  int inning = 0;

  bool isSeatsSwapped = false;

  late VideoManager videoManager;

  bool _isLoading = true;
  late int _localDelay;

  Soundpool pool = Soundpool(streamType: StreamType.notification);
  late List<int> soundId = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  late StreamSubscription _messageSubscription;

  void _showRecordsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final matchData = Provider.of<MatchData>(context, listen: false);
        return AlertDialog(
          title: Text('Game Records'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Player 1')),
                  DataColumn(label: Text('Inning')),
                  DataColumn(label: Text('Player 2')),
                ],
                rows: matchData.inningHistory
                    .map((inning) => DataRow(
                          cells: [
                            DataCell(Text(inning['player1'].toString())),
                            DataCell(Text(inning['inning'].toString())),
                            DataCell(Text(inning['player2'].toString())),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 15;
    double playtimeFontSize = screenHeight / 20;
    final matchData = Provider.of<MatchData>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'NICE ',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Q',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _reloadVideo,
            tooltip: 'Reload Video',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left player section (P1)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                    flex: 5,
                    child: _buildPlayerSection(isSeatsSwapped ? 1 : 0)),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _showRecordsDialog,
                        child: Text('RECORDS', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Center section (Video and controls)
          Expanded(
            flex: 7,
            child: Column(
              children: [
                // Video player
                Expanded(
                  flex: 4,
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            children: [
                              Video(
                                  controller: videoManager.controller,
                                  controls: NoVideoControls),
                              CustomVideoControls(
                                controller: videoManager.controller,
                                defaultDelay: videoManager.currentDelay,
                              ),
                            ],
                          ),
                        ),
                ),
                // Video controls
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _localDelay += 1;
                            videoManager
                                .setDelay(Duration(seconds: _localDelay));
                          });
                        },
                        label: Text(
                          "1 SEC SLOWER",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 40),
                      ElevatedButton.icon(
                        onPressed: () async {
                          setState(() {
                            _localDelay = (_localDelay - 1)
                                .clamp(0, double.infinity)
                                .toInt();
                            videoManager
                                .setDelay(Duration(seconds: _localDelay));
                          });
                        },
                        label: Text("1 SEC FASTER",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                // Game info and controls
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Inning: ${matchData.inning}  Time: $formattedTime',
                          style: TextStyle(fontSize: 24)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: !isGameStarted
                                ? () => startGame(matchData)
                                : () => finishGame(matchData),
                            child: Text(!isGameStarted ? 'START' : 'FINISH',
                                style: TextStyle(fontSize: 24)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isGameStarted
                                  ? Color.fromRGBO(37, 37, 38, 0.973)
                                  : Colors.redAccent,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                            ),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () => matchData.undo(),
                            child: Text('UNDO', style: TextStyle(fontSize: 24)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right player section (P2)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                    flex: 5,
                    child: _buildPlayerSection(isSeatsSwapped ? 0 : 1)),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isSeatsSwapped = !isSeatsSwapped;
                              });
                            },
                            child: Column(
                              children: [
                                Text('CHANGE', style: TextStyle(fontSize: 14)),
                                Text('SEAT', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                matchData.toggleColors();
                              });
                            },
                            child: Column(
                              children: [
                                Text('CHANGE', style: TextStyle(fontSize: 14)),
                                Text('BALL', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _messageSubscription =
        widget.webSocketService.messageStream.listen((message) {
      if (message == 'ForceStartGame') {
        if (!isTimerRunning) {
          print("Forcing game start");
          _startGameWithoutConfirmation(
              Provider.of<MatchData>(context, listen: false));
        }
      } else if (message == 'ForceEndGame') {
        if (isTimerRunning) {
          print("Forcing game end");
          _finishGameWithoutConfirmation(
              Provider.of<MatchData>(context, listen: false));
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
    final gameData = Provider.of<GameData>(context, listen: false);

    _localDelay = Provider.of<GameData>(context, listen: false).defaultDelay;

    videoManager = VideoManager(gameData);
    _initializeVideo();

    _settingButtonSound();
  }

  Future<void> _initializeVideo() async {
    final gameData = Provider.of<GameData>(context, listen: false);
    try {
      await videoManager.initialize(gameData.camera_uri);
      await videoManager.play(); // 이 라인 추가 필요
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Video initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비디오 초기화 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  void _initializeData() {
    final gameData = Provider.of<GameData>(context, listen: false);
    final matchData = Provider.of<MatchData>(context, listen: false);

    matchData.initializePlayers(
      widget.player1,
      widget.player2,
      widget.webSocketService,
    );

    setState(() {});
  }

  Future<void> _settingButtonSound() async {
    soundId[0] = await rootBundle
        .load("assets/woodclick.wav")
        .then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[1] =
        await rootBundle.load("assets/1p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[2] =
        await rootBundle.load("assets/2p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[3] =
        await rootBundle.load("assets/3p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[4] =
        await rootBundle.load("assets/4p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[5] =
        await rootBundle.load("assets/5p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[6] =
        await rootBundle.load("assets/winner.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[7] =
        await rootBundle.load("assets/onep.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[8] =
        await rootBundle.load("assets/twop.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[9] =
        await rootBundle.load("assets/threep.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[10] =
        await rootBundle.load("assets/fanfare.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[11] =
        await rootBundle.load("assets/start.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
  }

  void _reloadVideo() async {
    setState(() {
      _isLoading = true;
    });
    _initializeVideo();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    videoManager.dispose();
    pool.dispose();

    if (_timer != null) {
      _timer.cancel();
    }
    super.dispose();
  }

  void startGame(MatchData matchData) {
    if (isTimerRunning) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start Game'),
          content: Text('Are you sure you want to start the game?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startGameConfirmed(matchData);
                isGameStarted = true;
              },
              child: Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _startGameWithoutConfirmation(MatchData matchData) {
    setState(() {
      isGameStarted = true;
    });
    _startGameConfirmed(matchData);
  }

  void _finishGameWithoutConfirmation(MatchData matchData) {
    setState(() {
      isGameStarted = false;
    });
    _finishGameConfirmed(matchData);
  }

  void _startGameConfirmed(MatchData matchData) async {
    DateTime today = DateTime.now();
    gameStartTime = DateTime.now();
    matchData.startGame(today, gameStartTime);
    startTimer();
    widget.webSocketService.sendMessage({
      'type': 'GameStarted',
      'tableId': Provider.of<GameData>(context, listen: false).tabletNumber,
    });

    await pool.play(soundId[11]);
  }

  void finishGame(MatchData matchData) {
    if (!isTimerRunning) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Finish Game'),
          content: Text('Are you sure you want to finish the game?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _finishGameConfirmed(matchData);
                isGameStarted = false;
              },
              child: Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _finishGameConfirmed(MatchData matchData) {
    DateTime today = DateTime.now();
    DateTime end = DateTime.now();
    matchData.finishGame(today, gameStartTime, end);
    matchData._resetMatchDataWithoutNotify(); // 매치 데이터 초기화
    finish();
    widget.webSocketService.sendMessage({
      'type': 'GameEnded',
      'tableId': Provider.of<GameData>(context, listen: false).tabletNumber,
    });
    Navigator.pop(context);
  }

  void startTimer() {
    if (!isTimerRunning) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          timerSeconds++;
          formattedTime = _formatTime(timerSeconds);
        });
      });
      setState(() {
        isTimerRunning = true;
      });
    }
  }

  void stopTimer() {
    if (isTimerRunning) {
      _timer.cancel();
      setState(() {
        isTimerRunning = false;
      });
    }
  }

  void resetTimer() {
    setState(() {
      timerSeconds = 0;
      formattedTime = '00:00:00';
    });
  }

  void finish() {
    if (isTimerRunning) {
      stopTimer();
    }
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Video'),
          content: Text('Are you sure you want to reset the video?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
            ),
            TextButton(
              child: Text('Reset'),
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                setState(() {
                  _isLoading = true;
                });
                _initializeVideo(); // 비디오 초기화
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerSection(int index) {
    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 15;

    final matchData = Provider.of<MatchData>(context);
    final account = matchData.accounts[index];
    final playerState = matchData.playerStates[index];

    bool isWhite = (index == 0 && !matchData.isColorSwapped) ||
        (index == 1 && matchData.isColorSwapped);

    return Center(
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                (index == matchData.currentPlayer) ? Colors.blue : Colors.black,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (index == matchData.currentPlayer) {
                        if (!matchData.isTurnFinished) {
                          matchData.finishTurn();
                          matchData.endTurn();
                        }
                      }
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        account.name,
                        style: TextStyle(
                            fontSize: scoreFontSize / 2, color: Colors.black),
                      ),
                      Text(
                        '${playerState.score}',
                        style: TextStyle(
                            fontSize: scoreFontSize, color: Colors.black),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(),
                    backgroundColor: isWhite ? Colors.white : Colors.yellow,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ave: ${playerState.average.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: scoreFontSize / 3, color: Colors.white),
                      ),
                      Text(
                        'Handicap: ${playerState.handicap}',
                        style: TextStyle(
                            fontSize: scoreFontSize / 3, color: Colors.white),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: matchData.currentPlayer != index,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          matchData.incrementScore(context, index);
                        });
                      },
                      child: Text(
                        '+1',
                        style: TextStyle(
                            fontSize: scoreFontSize / 2, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(),
                        backgroundColor: isWhite ? Colors.yellow : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomProgressBar extends StatefulWidget {
  final VideoController controller;

  CustomProgressBar({required this.controller});

  @override
  _CustomProgressBarState createState() => _CustomProgressBarState();
}

class _CustomProgressBarState extends State<CustomProgressBar> {
  late StreamSubscription<Duration> _durationSubscription;
  Duration _realDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _realDuration = widget.controller.player.state.duration;
    _durationSubscription =
        widget.controller.player.stream.duration.listen((duration) {
      setState(() {
        _realDuration = duration;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.controller.player.stream.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return SliderTheme(
          data: SliderThemeData(
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: position.inMilliseconds.toDouble(),
            max: _realDuration.inMilliseconds.toDouble(),
            onChanged: (value) {
              widget.controller.player
                  .seek(Duration(milliseconds: value.toInt()));
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _durationSubscription.cancel();
    super.dispose();
  }
}

class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class Account {
  final String name;
  final double initialAverage;
  final int initialHandicap;
  final int initialTotalShots;

  Account({
    required this.name,
    required this.initialAverage,
    required this.initialHandicap,
    required this.initialTotalShots,
  });
}

class PlayerState {
  int score;
  double average;
  int handicap;
  int totalShots;
  int turns;

  PlayerState({
    this.score = 0,
    this.average = 0.0,
    this.handicap = 30,
    this.totalShots = 0,
    this.turns = 0,
  });

  PlayerState copyWith({
    int? score,
    double? average,
    int? handicap,
    int? totalShots,
    int? turns,
  }) {
    return PlayerState(
      score: score ?? this.score,
      average: average ?? this.average,
      handicap: handicap ?? this.handicap,
      totalShots: totalShots ?? this.totalShots,
      turns: turns ?? this.turns,
    );
  }
}

class GameState {
  final List<PlayerState> playerStates;
  final int currentPlayer;
  final int inning;
  final bool isTurnFinished;
  final List<Map<String, dynamic>> inningHistory;

  GameState({
    required this.playerStates,
    required this.currentPlayer,
    required this.inning,
    required this.isTurnFinished,
    required this.inningHistory,
  });

  GameState copyWith({
    List<PlayerState>? playerStates,
    int? currentPlayer,
    int? inning,
    bool? isTurnFinished,
    List<Map<String, dynamic>>? inningHistory,
  }) {
    return GameState(
      playerStates:
          playerStates ?? List.from(this.playerStates.map((p) => p.copyWith())),
      currentPlayer: currentPlayer ?? this.currentPlayer,
      inning: inning ?? this.inning,
      isTurnFinished: isTurnFinished ?? this.isTurnFinished,
      inningHistory: inningHistory ?? List.from(this.inningHistory),
    );
  }
}

class GameAction {
  final String type;
  final Map<String, dynamic> data;
  final GameState previousState;

  GameAction(this.type, this.data, this.previousState);
}

class MatchData with ChangeNotifier {
  GameState _currentState;
  List<GameAction> _undoStack = [];
  Soundpool pool = Soundpool(streamType: StreamType.notification);
  late List<int> soundId = [0, 0, 0, 0, 0, 0, 0, 0];
  bool _isColorSwapped = false;

  late GamePlayer _player1;
  late GamePlayer _player2;
  late WebSocketService _webSocketService;

  List<Account> accounts = [
    Account(
        name: "Player 1",
        initialAverage: 0,
        initialHandicap: 30,
        initialTotalShots: 0),
    Account(
        name: "Player 2",
        initialAverage: 0,
        initialHandicap: 30,
        initialTotalShots: 0),
  ];

  MatchData()
      : _currentState = GameState(
          playerStates: [
            PlayerState(average: 0, handicap: 30, totalShots: 0),
            PlayerState(average: 0, handicap: 30, totalShots: 0),
          ],
          currentPlayer: 0,
          inning: 1,
          isTurnFinished: false,
          inningHistory: [],
        ) {
    _initializeSounds();
  }

  void initializePlayers(GamePlayer p1, GamePlayer p2, WebSocketService ws) {
    _player1 = p1;
    _player2 = p2;
    _webSocketService = ws;
    accounts = [
      Account(
        name: p1.username,
        initialAverage: p1.average,
        initialHandicap: p1.handicap,
        initialTotalShots: p1.totalPlay,
      ),
      Account(
        name: p2.username,
        initialAverage: p2.average,
        initialHandicap: p2.handicap,
        initialTotalShots: p2.totalPlay,
      ),
    ];
    _resetMatchDataWithoutNotify();
    notifyListeners();
  }

  // Getters
  List<PlayerState> get playerStates => _currentState.playerStates;
  int get currentPlayer => _currentState.currentPlayer;
  int get inning => _currentState.inning;
  bool get isTurnFinished => _currentState.isTurnFinished;
  List<Map<String, dynamic>> get inningHistory => _currentState.inningHistory;
  bool get isColorSwapped => _isColorSwapped;
  List<int> get scores =>
      _currentState.playerStates.map((p) => p.score).toList();

  Future<void> _initializeSounds() async {
    soundId[0] = await rootBundle
        .load("assets/woodclick.wav")
        .then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[1] =
        await rootBundle.load("assets/1p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[2] =
        await rootBundle.load("assets/2p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[3] =
        await rootBundle.load("assets/3p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[4] =
        await rootBundle.load("assets/4p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[5] =
        await rootBundle.load("assets/5p.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    soundId[6] =
        await rootBundle.load("assets/winner.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
  }

  Future<void> _playSound(int index) async {
    await pool.play(soundId[index]);
  }

  void toggleColors() {
    _isColorSwapped = !_isColorSwapped;
    notifyListeners();
  }

  void incrementScore(BuildContext context, int playerIndex) {
    final previousState = _currentState;
    final newPlayerStates =
        _currentState.playerStates.map((p) => p.copyWith()).toList();
    int opponentIndex = 1 - playerIndex;
    newPlayerStates[opponentIndex].score++;
    newPlayerStates[opponentIndex].totalShots++;

    _currentState = _currentState.copyWith(playerStates: newPlayerStates);
    _undoStack.add(GameAction(
        'incrementScore', {'playerIndex': opponentIndex}, previousState));

    _updateAverageAndHandicap(opponentIndex);
    _checkScoreAndPlaySound(opponentIndex);
    checkWinner(context, opponentIndex);

    notifyListeners();
  }

  void _updateAverageAndHandicap(int playerIndex) {
    final player = _currentState.playerStates[playerIndex];
    if (player.turns > 0) {
      player.average = player.score / player.turns;
      print("Player $playerIndex new average: ${player.average}"); // 디버깅용 출력
    }
    // 여기에 핸디캡 계산 로직 추가 (필요한 경우)
    notifyListeners(); // 상태 변경 후 리스너에게 알림
  }

  void _checkScoreAndPlaySound(int playerIndex) {
    int handicap = _currentState.playerStates[playerIndex].handicap;
    int score = _currentState.playerStates[playerIndex].score;
    int remainingPoints = handicap - score;

    if (remainingPoints <= 5 && remainingPoints > 0) {
      _playSound(remainingPoints);
    } else if (remainingPoints <= 0) {
      _playSound(6); // 승리 사운드
    } else {
      _playSound(0); // 기본 클릭 사운드
    }
  }

  void finishTurn() {
    if (!_currentState.isTurnFinished) {
      final previousState = _currentState;
      final scoreThisTurn = _calculateScoreThisTurn();
      final newPlayerStates =
          _currentState.playerStates.map((p) => p.copyWith()).toList();
      newPlayerStates[_currentState.currentPlayer].turns++;

      _currentState = _currentState.copyWith(
        playerStates: newPlayerStates,
        isTurnFinished: true,
        inningHistory: [
          ..._currentState.inningHistory,
          {
            'player1': _currentState.currentPlayer == 0 ? scoreThisTurn : '-',
            'inning': _currentState.inning,
            'player2': _currentState.currentPlayer == 1 ? scoreThisTurn : '-',
          }
        ],
      );

      _updateAverageAndHandicap(_currentState.currentPlayer);

      _undoStack.add(GameAction(
          'finishTurn', {'scoreThisTurn': scoreThisTurn}, previousState));
      notifyListeners();
    }
  }

  void endTurn() {
    if (_currentState.isTurnFinished) {
      final previousState = _currentState;
      final newCurrentPlayer = _currentState.currentPlayer == 0 ? 1 : 0;
      final newInning = newCurrentPlayer == 0
          ? _currentState.inning + 1
          : _currentState.inning;

      _currentState = _currentState.copyWith(
        currentPlayer: newCurrentPlayer,
        inning: newInning,
        isTurnFinished: false,
      );
      _undoStack.add(GameAction('endTurn', {}, previousState));

      notifyListeners();
    }
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      final lastAction = _undoStack.removeLast();
      _currentState = lastAction.previousState;
      notifyListeners();
    }
  }

  int _calculateScoreThisTurn() {
    int scoreThisTurn = 0;
    int currentTurnStartIndex = _undoStack.length - 1;

    while (currentTurnStartIndex >= 0 &&
        _undoStack[currentTurnStartIndex].type != 'endTurn') {
      currentTurnStartIndex--;
    }

    for (int i = currentTurnStartIndex + 1; i < _undoStack.length; i++) {
      GameAction action = _undoStack[i];
      if (action.type == 'incrementScore' &&
          action.data['playerIndex'] == _currentState.currentPlayer) {
        scoreThisTurn++;
      }
    }

    return scoreThisTurn;
  }

  void _resetMatchDataWithoutNotify() {
    _currentState = GameState(
      playerStates: [
        PlayerState(
            average: accounts[0].initialAverage,
            handicap: accounts[0].initialHandicap,
            totalShots: accounts[0].initialTotalShots),
        PlayerState(
            average: accounts[1].initialAverage,
            handicap: accounts[1].initialHandicap,
            totalShots: accounts[1].initialTotalShots),
      ],
      currentPlayer: 0,
      inning: 1,
      isTurnFinished: false,
      inningHistory: [],
    );
    _undoStack.clear();
  }

  void startGame(DateTime today, DateTime gameStartTime) {
    // Game starting logic here
  }

  void finishGame(DateTime today, DateTime gameStartTime, DateTime end) {
    int totalTurns1 = playerStates[0].turns;
    int totalTurns2 = playerStates[1].turns;
    int totalScore1 = playerStates[0].score;
    int totalScore2 = playerStates[1].score;

    int newTotalPlay1 = _player1.totalPlay + totalTurns1;
    int newTotalPlay2 = _player2.totalPlay + totalTurns2;
    int newTotalScore1 = _player1.totalScore + totalScore1;
    int newTotalScore2 = _player2.totalScore + totalScore2;

    double newAverage1 = newTotalScore1 / newTotalPlay1;
    double newAverage2 = newTotalScore2 / newTotalPlay2;

    _webSocketService.updatePlayerStats(
        _player1.id, newAverage1, newTotalPlay1, newTotalScore1);
    _webSocketService.updatePlayerStats(
        _player2.id, newAverage2, newTotalPlay2, newTotalScore2);

    _player1.average = newAverage1;
    _player1.totalPlay = newTotalPlay1;
    _player1.totalScore = newTotalScore1;

    _player2.average = newAverage2;
    _player2.totalPlay = newTotalPlay2;
    _player2.totalScore = newTotalScore2;
  }

  void checkWinner(BuildContext context, int playerIndex) {
    int handicap = _currentState.playerStates[playerIndex].handicap;
    int score = _currentState.playerStates[playerIndex].score;

    if (score >= handicap) {
      String winnerName = accounts[playerIndex].name;
      showWinnerDialog(context, winnerName);
    }
  }

  void showWinnerDialog(BuildContext context, String winnerName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('$winnerName Win!', style: TextStyle(fontSize: 100)),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    pool.dispose();
    super.dispose();
  }
}
