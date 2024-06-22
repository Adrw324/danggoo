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
                    child: Center(
                      child: Text(
                        'Inning Table',
                        style: TextStyle(fontSize: playtimeFontSize),
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
                    backgroundColor: Colors.yellow,
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
                        Text('Average',
                            style: TextStyle(
                                fontSize: scoreFontSize / 3,
                                color: Colors.white)),
                        Text('Handicap',
                            style: TextStyle(
                                fontSize: scoreFontSize / 3,
                                color: Colors.white)),
                      ],
                    ),
                    if (matchData.currentPlayer != 0) // 현재 플레이어가 아니면 +1 버튼 표시
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            matchData.incrementScore(1); // Player 2의 점수 증가
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
                      )
                    else
                      Container(
                        width: scoreFontSize * 1.2,
                      ), // 공간 차지용 빈 컨테이너
                  ] else ...[
                    if (matchData.currentPlayer != 1) // 현재 플레이어가 아니면 +1 버튼 표시
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            matchData.incrementScore(0); // Player 1의 점수 증가
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
                      )
                    else
                      Container(
                        width: scoreFontSize * 1.2,
                      ), // 공간 차지용 빈 컨테이너
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Average',
                            style: TextStyle(
                                fontSize: scoreFontSize / 3,
                                color: Colors.white)),
                        Text('Handicap',
                            style: TextStyle(
                                fontSize: scoreFontSize / 3,
                                color: Colors.white)),
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

class MatchData with ChangeNotifier {
  List<int> _scores = [0, 0];
  List<Map<String, dynamic>> _inningHistory = []; // 이닝 기록
  int _currentPlayer = 0; // 0: Player 1, 1: Player 2
  bool _isTurnFinished = false; // 현재 턴 종료 여부
  List<Map<String, dynamic>> _undoStack = []; // 언두 스택
  int _inning = 1; // 현재 이닝

  List<int> get scores => _scores;
  int get currentPlayer => _currentPlayer;
  int get inning => _inning;
  bool get isTurnFinished => _isTurnFinished; // 현재 턴 종료 여부 가져오기

  void incrementScore(int playerIndex) {
    if (!_isTurnFinished) {
      _scores[playerIndex]++;
      _undoStack.add({'playerIndex': playerIndex, 'score': 1});
      notifyListeners();
    }
  }

  void finishTurn() {
    if (!_isTurnFinished) {
      _isTurnFinished = true;
      _undoStack.add({'action': 1}); // 턴 종료 액션 추가
      notifyListeners();
    }
  }

  void endTurn() {
    if (_isTurnFinished) {
      _currentPlayer = _currentPlayer == 0 ? 1 : 0;
      if (_currentPlayer == 0) {
        _inning++;
        _inningHistory.add({'inning': _inning, 'scores': List.from(_scores)});
        _undoStack.add({'action': 'endInning'});
      }
      _isTurnFinished = false;
      notifyListeners();
    }
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      Map<String, dynamic> lastAction = _undoStack.removeLast();
      if (lastAction.containsKey('score')) {
        int playerIndex = lastAction['playerIndex']!;
        int score = lastAction['score']!;
        _scores[playerIndex] -= score;
      } else if (lastAction['action'] == 1) {
        _isTurnFinished = false;
        _currentPlayer = _currentPlayer == 0 ? 1 : 0; // 턴 변경
      } else if (lastAction['action'] == 'endInning') {
        _inning--;
        if (_inningHistory.isNotEmpty) {
          _inningHistory.removeLast();
        }
      }
      notifyListeners();
    }
  }

  void resetMatchData() {
    _scores = [0, 0];
    _inningHistory.clear();
    _currentPlayer = 0;
    _isTurnFinished = false;
    _undoStack.clear();
    _inning = 1;
    notifyListeners();
  }

  void startGame(DateTime today, DateTime gameStartTime) {
    // Game starting logic here
  }

  void finishGame(DateTime today, DateTime gameStartTime, DateTime end) {
    // Game finishing logic here
  }
}
