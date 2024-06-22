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
    final gameData = Provider.of<GameData>(context);

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
                    child: _buildPlayerSection(0, buttonCounts),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Inning: $inning',
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
                    child: _buildPlayerSection(1, buttonCounts),
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
                            onPressed: () => startGame(gameData),
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
                            onPressed: () => finishGame(gameData),
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
                              onPressed: () {},
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
    // _startConversion();
    // await _waitForSegment();
    await _initializeController();
  }

  Future<void> _waitForSegment() async {
    while (!(await isSegmentGenerated())) {
      await Future.delayed(Duration(seconds: 1));
    }
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

  Future<void> _startConversion() async {
    await Directory(outputPath).create(recursive: true);
    _ffmpeg = FlutterFFmpeg();
    _runFFmpeg(inputPath, outputPath);
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

  Future<int> _runFFmpeg(String inputPath, String outputPath) async {
    List<String> arguments = [
      '-i',
      inputPath,
      '-c:v',
      'libx264',
      '-an',
      '-threads',
      '2',
      '-preset',
      'ultrafast',
      '-f',
      'hls',
      '-s',
      '960x540',
      '-hls_time',
      '4',
      '-crf',
      '28',
      '-hls_playlist_type',
      'event',
      '-hls_list_size',
      '0',
      '-hls_segment_filename',
      '$outputPath/output_%03d.ts',
      '$outputPath/output.m3u8',
    ];
    return await _ffmpeg.executeWithArguments(arguments);
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

  void startGame(GameData gameData) {
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
                _startGameConfirmed(gameData);
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

  void _startGameConfirmed(GameData gameData) {
    DateTime today = DateTime.now();
    gameStartTime = DateTime.now();
    int table = gameData.tabletNumber;
    Game game = Game(
      tableNum: table,
      date: today.toIso8601String(),
      start: gameStartTime.toIso8601String(),
      end: gameStartTime.toIso8601String(),
      playtime: 0,
      fee: 0,
      finished: false,
    );

    GameDataSender gameDataSender = GameDataSender();
    gameDataSender.sendGameData(game, gameData);

    startTimer();
  }

  void finishGame(GameData gameData) {
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
                _finishGameConfirmed(gameData);
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

  void _finishGameConfirmed(GameData gameData) {
    DateTime today = DateTime.now();
    DateTime end = DateTime.now();
    int table = gameData.tabletNumber;
    double fpm = gameData.feePerMinute;

    Duration timeDifference = end.difference(gameStartTime);
    int minutesDifference = timeDifference.inMinutes;

    Game game = Game(
      tableNum: table,
      date: today.toIso8601String(),
      start: gameStartTime.toIso8601String(),
      end: end.toIso8601String(),
      playtime: minutesDifference,
      fee: minutesDifference * fpm,
      finished: true,
    );

    GameDataSender gameDataSender = GameDataSender();
    gameDataSender.sendGameData(game, gameData);

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

  Future<void> incrementButtonCountBy(int index) async {
    setState(() {
      buttonCounts[index] += 1;
    });
    _checkTurn();
    checkWinner();
  }

  void turnOffAll() {
    isAnyButtonOn = false;
  }

  void _checkTurn() {
    setState(() {
      if (currentPlayer == 0) {
        currentPlayer = 1;
      } else {
        currentPlayer = 0;
        inning++;
      }
    });
  }

  void checkWinner() {
    // 빈 함수
  }

  Widget _buildPlayerSection(int index, List<int> buttonCounts) {
    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 15;

    return Center(
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      color: Color.fromRGBO(37, 37, 38, 0.973),
                      child: Center(
                        child: Text(
                          'PLAYER ${index + 1}',
                          style: TextStyle(fontSize: scoreFontSize / 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isAnyButtonOn) {
                      setState(() {
                        incrementButtonCountBy(index);
                      });
                    } else {
                      setState(() {
                        isAnyButtonOn = true;
                      });
                    }
                  },
                  child: Text(
                    '${buttonCounts[index]}',
                    style:
                        TextStyle(fontSize: scoreFontSize, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(),
                    backgroundColor: Colors.yellow,
                  ),
                ),
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
