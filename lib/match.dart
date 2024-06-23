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

class MatchScreen extends StatefulWidget {
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

  late FlutterFFmpeg _ffmpeg;
  late String inputPath =
      'rtsp://admin:a1234567@192.168.50.106:554/h264Preview_01_main';
  late String documentDirectory;
  late String outputPath;
  late final player = Player();
  late final controller = VideoController(player);
  bool _isLoading = true;

  Soundpool pool = Soundpool(streamType: StreamType.notification);
  late List<int> soundId = [0, 0, 0, 0, 0, 0, 0, 0];

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
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'Q',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            isAnyButtonOn = false;
          });
        },
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildPlayerSection(0, matchData.scores[0]),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Inning: ${matchData.inning}',
                          style: TextStyle(fontSize: playtimeFontSize),
                        ),
                        SizedBox(height: 16),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: playtimeFontSize),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildPlayerSection(1, matchData.scores[1]),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          DataTable(
                            columns: [
                              DataColumn(
                                  label: Text('Player 1',
                                      style: TextStyle(
                                          fontSize: playtimeFontSize / 3))),
                              DataColumn(
                                  label: Text('Inning',
                                      style: TextStyle(
                                          fontSize: playtimeFontSize / 3))),
                              DataColumn(
                                  label: Text('Player 2',
                                      style: TextStyle(
                                          fontSize: playtimeFontSize / 3))),
                            ],
                            rows: matchData.inningHistory
                                .map(
                                  (inning) => DataRow(
                                    cells: [
                                      DataCell(Text(
                                        inning['player1'].toString(),
                                        style: TextStyle(
                                            fontSize: playtimeFontSize / 3),
                                      )),
                                      DataCell(Text(
                                        inning['inning'].toString(),
                                        style: TextStyle(
                                            fontSize: playtimeFontSize / 3),
                                      )),
                                      DataCell(Text(
                                        inning['player2'].toString(),
                                        style: TextStyle(
                                            fontSize: playtimeFontSize / 3),
                                      )),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Video(controller: controller),
                                  ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await player.seek(player.state.position -
                                      Duration(seconds: 5));
                                },
                                child: Icon(Icons.replay_5,
                                    size: 35, color: Colors.white),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await player.seek(player.state.position +
                                      Duration(seconds: 5));
                                },
                                child: Icon(Icons.forward_5,
                                    size: 35, color: Colors.white),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await player.seek(player.state.duration);
                                },
                                child: Text(
                                  'LIVE',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 25),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  _initialize();
                                },
                                child: Text(
                                  'Reset',
                                  style: TextStyle(
                                      color: Colors.teal, fontSize: 25),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isGameStarted)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromRGBO(37, 37, 38, 0.973),
                            ),
                            onPressed: () => startGame(matchData),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Container(
                                child: Center(
                                  child: Text('START',
                                      style: TextStyle(
                                          fontSize: 50, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                        if (isGameStarted)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () => finishGame(matchData),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Container(
                                child: Center(
                                  child: Text('FINISH',
                                      style: TextStyle(
                                          fontSize: 50, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  matchData.undo();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Container(
                                  child: Center(
                                    child: Text('UNDO',
                                        style: TextStyle(
                                            fontSize: 30, color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                // 공 색깔 바꾸는 로직 추가 예정
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                child: Center(
                                  child: ClipPath(
                                    clipper: DiagonalClipper(),
                                    child: Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.yellow,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white,
                                ),
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
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final gameData = Provider.of<GameData>(context, listen: false);

    inputPath = gameData.camera_uri;

    _settingButtonSound();
    _initialize();
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
  }

  Future<void> _initialize() async {
    await _getDirectory();
    await _deleteFilesInDirectory(outputPath);
    await _initializeController();
  }

  Future<void> _initializeController() async {
    File file = File(outputPath + "/output.m3u8");

    if (await file.exists()) {
      player.open(Media('file://' + outputPath + "/output.m3u8"));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getDirectory() async {
    documentDirectory = await _getDocumentDirectory();
    outputPath = '$documentDirectory/ffmpeg_output';
  }

  Future<bool> isSegmentGenerated() async {
    Directory directory = Directory(outputPath);
    if (await directory.exists()) {
      List<FileSystemEntity> files = directory.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.ts')) {
          return true;
        }
      }
    }
    return false;
  }

  Future<String> _getDocumentDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _deleteFilesInDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting files: $e');
    }
  }

  @override
  void dispose() {
    Future.delayed(Duration.zero, () async {
      try {
        await _deleteFilesInDirectory(outputPath);
        await _ffmpeg.cancel();
      } catch (e) {
        print('Error during dispose: $e');
      }
    });

    player.dispose();
    pool.dispose();
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

  void _startGameConfirmed(MatchData matchData) {
    DateTime today = DateTime.now();
    gameStartTime = DateTime.now();
    matchData.startGame(today, gameStartTime);
    startTimer();
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
    matchData.resetMatchData(); // 매치 데이터 초기화
    finish();
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

  Widget _buildPlayerSection(int index, int score) {
    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 15;

    final matchData = Provider.of<MatchData>(context);

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
                          matchData.endTurn(); // 바로 다음 플레이어로 넘어가도록 수정
                        }
                      }
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PLAYER ${index + 1}', // 플레이어 이름 섹션 추가
                        style: TextStyle(
                            fontSize: scoreFontSize / 2, color: Colors.black),
                      ),
                      Text(
                        '$score',
                        style: TextStyle(
                            fontSize: scoreFontSize, color: Colors.black),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(),
                    backgroundColor: index == 0 ? Colors.white : Colors.yellow,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (index == 0) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Average',
                          style: TextStyle(
                              fontSize: scoreFontSize / 3, color: Colors.white),
                        ),
                        Text(
                          'Handicap',
                          style: TextStyle(
                              fontSize: scoreFontSize / 3, color: Colors.white),
                        ),
                      ],
                    ),
                    Visibility(
                      visible: matchData.currentPlayer != 0,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            matchData
                                .incrementScore(index); // 현재 플레이어가 아닌 경우만 증가
                          });
                        },
                        child: Text(
                          '+1',
                          style: TextStyle(
                              fontSize: scoreFontSize / 2, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(),
                          backgroundColor: Colors.yellow,
                        ),
                      ),
                    )
                  ] else ...[
                    Visibility(
                      visible: matchData.currentPlayer != 1,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            matchData
                                .incrementScore(index); // 현재 플레이어가 아닌 경우만 증가
                          });
                        },
                        child: Text(
                          '+1',
                          style: TextStyle(
                              fontSize: scoreFontSize / 2, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Average',
                          style: TextStyle(
                              fontSize: scoreFontSize / 3, color: Colors.white),
                        ),
                        Text(
                          'Handicap',
                          style: TextStyle(
                              fontSize: scoreFontSize / 3, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

class GameState {
  final List<int> scores;
  final int currentPlayer;
  final int inning;
  final bool isTurnFinished;
  final List<Map<String, dynamic>> inningHistory;

  GameState({
    required this.scores,
    required this.currentPlayer,
    required this.inning,
    required this.isTurnFinished,
    required this.inningHistory,
  });

  GameState copyWith({
    List<int>? scores,
    int? currentPlayer,
    int? inning,
    bool? isTurnFinished,
    List<Map<String, dynamic>>? inningHistory,
  }) {
    return GameState(
      scores: scores ?? List.from(this.scores),
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

  MatchData()
      : _currentState = GameState(
          scores: [0, 0],
          currentPlayer: 0,
          inning: 1,
          isTurnFinished: false,
          inningHistory: [],
        );

  // Getters
  List<int> get scores => _currentState.scores;
  int get currentPlayer => _currentState.currentPlayer;
  int get inning => _currentState.inning;
  bool get isTurnFinished => _currentState.isTurnFinished;
  List<Map<String, dynamic>> get inningHistory => _currentState.inningHistory;

  void incrementScore(int playerIndex) {
    final previousState = _currentState;
    final newScores = List<int>.from(_currentState.scores);
    // 상대방의 점수를 올립니다.
    int opponentIndex = 1 - playerIndex;
    newScores[opponentIndex]++;

    _currentState = _currentState.copyWith(scores: newScores);
    _undoStack.add(GameAction(
        'incrementScore', {'playerIndex': opponentIndex}, previousState));
    notifyListeners();
  }

  void finishTurn() {
    if (!_currentState.isTurnFinished) {
      final previousState = _currentState;
      final scoreThisTurn = _calculateScoreThisTurn();
      final newInningHistory =
          List<Map<String, dynamic>>.from(_currentState.inningHistory);
      newInningHistory.add({
        'player1': _currentState.currentPlayer == 0 ? scoreThisTurn : '-',
        'inning': _currentState.inning,
        'player2': _currentState.currentPlayer == 1 ? scoreThisTurn : '-',
      });

      _currentState = _currentState.copyWith(
        isTurnFinished: true,
        inningHistory: newInningHistory,
      );
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

  void resetMatchData() {
    _currentState = GameState(
      scores: [0, 0],
      currentPlayer: 0,
      inning: 1,
      isTurnFinished: false,
      inningHistory: [],
    );
    _undoStack.clear();
    notifyListeners();
  }

  int _calculateScoreThisTurn() {
    int scoreThisTurn = 0;
    int currentTurnStartIndex = _undoStack.length - 1;

    // 현재 턴의 시작 지점을 찾습니다.
    while (currentTurnStartIndex >= 0 &&
        _undoStack[currentTurnStartIndex].type != 'endTurn') {
      currentTurnStartIndex--;
    }

    // 현재 턴의 시작부터 끝까지 점수 증가 액션을 찾아 합산합니다.
    for (int i = currentTurnStartIndex + 1; i < _undoStack.length; i++) {
      GameAction action = _undoStack[i];
      if (action.type == 'incrementScore' &&
          action.data['playerIndex'] == _currentState.currentPlayer) {
        scoreThisTurn++;
      }
    }

    return scoreThisTurn;
  }

  void startGame(DateTime today, DateTime gameStartTime) {
    // 게임 시작 로직
    // 필요한 경우 여기에 구현
  }

  void finishGame(DateTime today, DateTime gameStartTime, DateTime end) {
    // 게임 종료 로직
    // 필요한 경우 여기에 구현
  }
}
