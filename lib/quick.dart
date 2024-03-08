import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'global.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_playout/video.dart';
import 'package:flutter_playout/player_state.dart';

class QuickStartWidget extends StatefulWidget {
  const QuickStartWidget({super.key});

  @override
  State<QuickStartWidget> createState() => _QuickStartWidgetState();
}

class _QuickStartWidgetState extends State<QuickStartWidget> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class QuickStartScreen extends StatefulWidget {
  final int playerCount;

  QuickStartScreen({required this.playerCount});

  @override
  _QuickStartScreenState createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends State<QuickStartScreen> {
  late Timer _timer;
  bool isTimerRunning = false;
  bool isGameStarted = false;
  int timerSeconds = 0;
  String formattedTime = '00:00:00';
  List<int> buttonCounts = [];
  DateTime gameStartTime = DateTime.now();
  bool colorChanged = false;
  bool isAnyButtonOn = false;

  List<bool> isPressed = [false, false, false, false, false, false];

  late FlutterFFmpeg _ffmpeg;

  String inputPath =
      'rtsp://admin:a1234567@192.168.50.106:554/h264Preview_01_main';

  late String documentDirectory;

  late String outputPath;

  bool _isLoading = true;

  PlayerState _desiredState = PlayerState.PLAYING;

  double _position = 0;

  Video _video = Video();

  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();

    FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 10;
    double scoreBtnFontSize = screenHeight / 14;
    double PlaytimeFontSize = screenHeight / 8;

    List<Widget> playerSections = [];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'NICE ',
                style: TextStyle(
                  color: Colors.white, // 하얀색
                  fontSize: 20, // 원하는 폰트 크기로 조정
                  fontWeight: FontWeight.bold, // 원하는 폰트 두께로 조정
                ),
              ),
              TextSpan(
                text: 'Q',
                style: TextStyle(
                  color: Colors.red, // 빨강색
                  fontSize: 20, // 원하는 폰트 크기로 조정
                  fontWeight: FontWeight.bold, // 원하는 폰트 두께로 조정
                ),
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            turnOffAll();
            isAnyButtonOn = false;
          });
        },
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                    // border: Border.all(color: Colors.black),
                    ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.playerCount < 5
                      ? List.generate((widget.playerCount / 2).ceil(), (index) {
                          final playerIndex = index * 2;
                          if (widget.playerCount == 2)
                            return _buildPlayerSection(
                                playerIndex, widget.playerCount);
                          else
                            return _buildPlayerSection3(
                                playerIndex, widget.playerCount);
                        })
                      : List.generate((widget.playerCount / 2).ceil(), (index) {
                          final playerIndex = index * 2;
                          return _buildPlayerSection5(
                              playerIndex, widget.playerCount);
                        }),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                    // border: Border.all(color: Colors.black),
                    ),
                child: Center(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Scaffold(
                          appBar: null,
                          body: Column(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Center(
                                  child: _isLoading
                                      ? Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: _video,
                                        ),
                                ),
                              ),
                              // Expanded(
                              //   flex: 1,
                              //   child: Center(
                              //     child: Row(
                              //       mainAxisAlignment: MainAxisAlignment.center,
                              //       children: [
                              //         ElevatedButton(
                              //           onPressed: () {
                              //             setState(() {
                              //               _position -= 5;
                              //             });
                              //           },
                              //           child: Icon(Icons.arrow_back),
                              //         ),
                              //         ElevatedButton(
                              //           onPressed: () {
                              //             setState(() {
                              //               _desiredState == PlayerState.PLAYING
                              //                   ? _desiredState =
                              //                       PlayerState.PAUSED
                              //                   : _desiredState =
                              //                       PlayerState.PLAYING;
                              //             });
                              //           },
                              //           child: Icon(
                              //             _desiredState == PlayerState.PLAYING
                              //                 ? Icons.pause
                              //                 : Icons.play_arrow,
                              //           ),
                              //         ),
                              //         ElevatedButton(
                              //           onPressed: () {
                              //             setState(() {
                              //               _position += 5;
                              //             });
                              //           },
                              //           child: Icon(Icons.arrow_forward),
                              //         ),
                              //         // ElevatedButton(
                              //         //   onPressed: () {
                              //         //     Duration targetPosition =
                              //         //         _controller.value.duration -
                              //         //             const Duration(seconds: 5);
                              //         //     _controller.seekTo(targetPosition);
                              //         //   },
                              //         //   child: Text('LIVE'),
                              //         // ),
                              //         ElevatedButton(
                              //           onPressed: () {
                              //             _enterFullScreen();
                              //           },
                              //           child: Text('FULL'),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                formattedTime,
                                style: TextStyle(fontSize: PlaytimeFontSize),
                              ),
                              SizedBox(height: 16),
                              Row(
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
                                                        fontSize: 50,
                                                        color: Colors.white)))),
                                      ),
                                    ),
                                  if (isGameStarted)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      onPressed: () => finishGame(
                                          gameData), // Finish 버튼 클릭 시 데이터 전송
                                      child: Padding(
                                        padding: const EdgeInsets.all(15.0),
                                        child: Container(
                                            child: Center(
                                                child: Text('FINISH',
                                                    style: TextStyle(
                                                        fontSize: 50,
                                                        color: Colors.white)))),
                                      ),
                                    ),
                                  if (widget.playerCount % 2 == 0)
                                    Padding(
                                      padding: const EdgeInsets.all(15.0),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (colorChanged) {
                                              colorChanged = false;
                                            } else {
                                              colorChanged = true;
                                            }
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Color.fromARGB(
                                                  255, 255, 217, 0)),
                                          child: ClipPath(
                                            clipper: DiagonalClipper(),
                                            child: Container(
                                                height: 80,
                                                width: 80,
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    10)))),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // ElevatedButton(onPressed: (){
                                  //  setState(() {
                                  //    if(colorChanged) {
                                  //     colorChanged = false;
                                  //   }
                                  //   else {
                                  //     colorChanged = true;
                                  //   }
                                  //  });
                                  // },
                                  // style: ElevatedButton.styleFrom(
                                  //     backgroundColor: Colors.black,
                                  // ),
                                  // child: Padding(
                                  //   padding: const EdgeInsets.all(15.0),
                                  //   child: Text('CHANGE',
                                  //                   style: TextStyle(
                                  //                       fontSize: 50,
                                  //                       color: Colors.white)),
                                  // ))
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                    // border: Border.all(color: Colors.black),
                    ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.playerCount < 5
                      ? List.generate((widget.playerCount / 2).floor(),
                          (index) {
                          final playerIndex = index * 2 + 1;
                          if (widget.playerCount == 2)
                            return _buildPlayerSection(
                                playerIndex, widget.playerCount);
                          else
                            return _buildPlayerSection3(
                                playerIndex, widget.playerCount);
                        })
                      : List.generate((widget.playerCount / 2).floor(),
                          (index) {
                          final playerIndex = index * 2 + 1;
                          return _buildPlayerSection5(
                              playerIndex, widget.playerCount);
                        }),
                ),
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

    buttonCounts = List<int>.filled(widget.playerCount, 0);

    _initialize();
  }

  Future<void> _initialize() async {
    await _getDirectory();
    await _deleteFilesInDirectory(outputPath);
    _startConversion();
    await _waitForSegment();
    await _initializeController();
  }

  Future<void> _waitForSegment() async {
    // 일정 간격으로 isSegmentGenerated를 체크하다가 생성되면 반환
    while (!(await isSegmentGenerated())) {
      await Future.delayed(Duration(seconds: 1)); // 적절한 간격으로 조절
    }
  }

  Future<void> _initializeController() async {
    print('Initializing Controller!!!');
    // _controller = VideoPlayerController.file(File(outputPath + '/output.m3u8'))
    //   ..initialize().then((_) {
    //     _controller.play();
    //     setState(() {
    //       _isLoading = false;
    //     });
    //   });

    // betterPlayerDataSource = BetterPlayerDataSource(
    //     BetterPlayerDataSourceType.file, outputPath + "/output.m3u8");

    File file = File(outputPath + "/output.m3u8");

    if (await file.exists()) {
      print('파일이 존재합니다.');
    } else {
      print('파일이 존재하지 않습니다.');
    }

    _video = Video(
        position: _position,
        desiredState: _desiredState,
        showControls: true,
        autoPlay: true,
        url: outputPath + "/output.m3u8");

    setState(() {
      _isLoading = false;
      print('DDDDDD');
      print(_isLoading);
    });
  }

  Future<void> _getDirectory() async {
    documentDirectory = await _getDocumentDirectory();

    // Create a subdirectory in the document directory to save the files
    outputPath = '$documentDirectory/ffmpeg_output';
  }

  Future<void> _startConversion() async {
    print('AAA');

    await Directory(outputPath).create(recursive: true);
    _ffmpeg = FlutterFFmpeg();
    // Execute the FFmpeg command
    _runFFmpeg(inputPath, outputPath);
  }

  Future<bool> isSegmentGenerated() async {
    Directory directory = Directory(outputPath);
    if (await directory.exists()) {
      List<FileSystemEntity> files = directory.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.m3u8')) {
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
      '4',
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
      '-loglevel',
      'quiet',
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
        print('Files in $directoryPath deleted successfully.');
      } else {
        print('Directory $directoryPath does not exist.');
      }
    } catch (e) {
      print('Error deleting files: $e');
    }
  }

  void _enterFullScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _video,
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    Future.delayed(Duration.zero, () async {
      try {
        await _deleteFilesInDirectory(outputPath);
        print('Files Deleted!');
        await _ffmpeg.cancel();
      } catch (e) {
        print('Error during dispose: $e');
      }
    });

    print('Disposed!');

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
                Navigator.of(context).pop(); // Close the dialog
                _startGameConfirmed(gameData);
                isGameStarted = true;
              },
              child: Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
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
                Navigator.of(context).pop(); // Close the dialog
                _finishGameConfirmed(gameData);
                isGameStarted = false;
              },
              child: Text('Confirm'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
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

  void incrementButtonCountBy(int index, int count) {
    setState(() {
      buttonCounts[index] += count;
    });
  }

  void decrementButtonCount(int index) {
    if (buttonCounts[index] > 0) {
      setState(() {
        buttonCounts[index]--;
      });
    }
  }

  void turnOffAll() {
    isPressed[0] = false;
    isPressed[1] = false;
    isPressed[2] = false;
    isPressed[3] = false;
    isPressed[4] = false;
    isPressed[5] = false;
  }

  Widget _buildPlayerSection5(int index, int playerCount) {
    List<Color> colors = [
      Color.fromARGB(255, 255, 255, 255),
      Color.fromARGB(255, 255, 217, 0),
      // Color.fromARGB(255, 187, 61, 3),
      // Color.fromARGB(255, 202, 103, 2),
      // Color.fromARGB(255, 238, 155, 0),
      // Color.fromARGB(255, 0, 95, 115),
      // Color.fromARGB(255, 10, 147, 150),
      // Color.fromARGB(255, 233, 216, 166),
    ];

    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 8;
    double scoreBtnFontSize = screenHeight / 50;
    double playerFontSize = screenHeight / 30;
    return Center(
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Container(
          margin: const EdgeInsets.only(left: 10.0, right: 10.0),
          height: MediaQuery.of(context).size.height / 5,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
            color: isPressed[index] ? Colors.lightBlue : Colors.transparent,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(37, 37, 38, 0.973),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Color.fromRGBO(37, 37, 38, 0.973),
                    child: Center(
                      child: Text(
                        'Player ${index + 1}',
                        style: TextStyle(fontSize: playerFontSize),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (isAnyButtonOn) {
                                        if (isPressed[index]) {
                                          setState(() {
                                            incrementButtonCountBy(index, 2);
                                          });
                                        } else {
                                          setState(() {
                                            turnOffAll();
                                            isAnyButtonOn = false;
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          turnOffAll();
                                          isPressed[index] = true;
                                          isAnyButtonOn = true;
                                        });
                                      }
                                    },
                                    child: Text(
                                      '+2',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: scoreBtnFontSize),
                                      softWrap: false,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                        ),
                                        backgroundColor:
                                            Color.fromARGB(1, 2, 52, 161)
                                        // side: BorderSide(
                                        // width: 1.0, color: Colors.blue)
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (isAnyButtonOn) {
                                        if (isPressed[index]) {
                                          setState(() {
                                            incrementButtonCountBy(index, 3);
                                          });
                                        } else {
                                          setState(() {
                                            turnOffAll();
                                            isAnyButtonOn = false;
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          turnOffAll();
                                          isPressed[index] = true;
                                          isAnyButtonOn = true;
                                        });
                                      }
                                    },
                                    child: Text(
                                      '+3',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: scoreBtnFontSize),
                                      softWrap: false,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      backgroundColor:
                                          Color.fromARGB(1, 2, 52, 161),
                                      // side: BorderSide(
                                      // width: 1.0, color: Colors.blue)
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          child: AspectRatio(
                              aspectRatio: 1,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (isAnyButtonOn) {
                                    if (isPressed[index]) {
                                      setState(() {
                                        incrementButtonCountBy(index, 1);
                                      });
                                    } else {
                                      setState(() {
                                        turnOffAll();
                                        isAnyButtonOn = false;
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      turnOffAll();
                                      isPressed[index] = true;
                                      isAnyButtonOn = true;
                                    });
                                  }
                                },
                                child: Text(
                                  '${buttonCounts[index]}',
                                  style: TextStyle(
                                      fontSize: scoreFontSize,
                                      color: Colors.black),
                                  softWrap: false,
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  backgroundColor: () {
                                    if (playerCount % 2 != 0) {
                                      return Color.fromARGB(255, 255, 228, 168);
                                    } else {
                                      if (colorChanged)
                                        return colors[(index + 1) % 2];
                                      else
                                        return colors[index % 2];
                                    }
                                  }(),
                                  // side: BorderSide(
                                  // width: 3.0, color: Colors.white)
                                ),
                              )),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (isAnyButtonOn) {
                                        if (isPressed[index]) {
                                          setState(() {
                                            incrementButtonCountBy(index, 5);
                                          });
                                        } else {
                                          setState(() {
                                            turnOffAll();
                                            isAnyButtonOn = false;
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          turnOffAll();
                                          isPressed[index] = true;
                                          isAnyButtonOn = true;
                                        });
                                      }
                                    },
                                    child: Text(
                                      '+5',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: scoreBtnFontSize),
                                      softWrap: false,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                        ),
                                        backgroundColor:
                                            Color.fromARGB(1, 2, 52, 161)
                                        // side: BorderSide(
                                        // width: 1.0, color: Colors.blue)
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (isAnyButtonOn) {
                                        if (isPressed[index]) {
                                          setState(() {
                                            decrementButtonCount(index);
                                          });
                                        } else {
                                          setState(() {
                                            turnOffAll();
                                            isAnyButtonOn = false;
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          turnOffAll();
                                          isPressed[index] = true;
                                          isAnyButtonOn = true;
                                        });
                                      }
                                    },
                                    child: Text(
                                      '-1',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: scoreBtnFontSize),
                                      softWrap: false,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      backgroundColor:
                                          Color.fromARGB(222, 255, 132, 0),
                                      // side: BorderSide(
                                      // width: 1.0, color: Colors.blue)
                                    ),
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildPlayerSection3(int index, int playerCount) {
    List<Color> colors = [
      Color.fromARGB(255, 255, 255, 255),
      Color.fromARGB(255, 255, 217, 0),
      // Color.fromARGB(255, 187, 61, 3),
      // Color.fromARGB(255, 202, 103, 2),
      // Color.fromARGB(255, 238, 155, 0),
      // Color.fromARGB(255, 0, 95, 115),
      // Color.fromARGB(255, 10, 147, 150),
      // Color.fromARGB(255, 233, 216, 166),
    ];

    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 8;
    double scoreBtnFontSize = screenHeight / 50;
    double playerFontSize = screenHeight / 30;
    double buttonSize = screenHeight / 4.5;

    return Center(
      child: AspectRatio(
        aspectRatio: 1.08,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
            color: isPressed[index] ? Colors.lightBlue : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Container(
              margin: const EdgeInsets.only(left: 10.0, right: 10.0),
              height: MediaQuery.of(context).size.height / 3.2,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromRGBO(37, 37, 38, 0.973),
                // color: Color.fromRGBO(3, 35, 73, 1)
                // boxShadow: [
                // BoxShadow(
                // color: Colors.grey,
                // offset: const Offset(3.0, 3.0),
                // blurRadius: 2.0,
                // spreadRadius: 1.0,
                // )
                // ]
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Color.fromRGBO(37, 37, 38, 0.973),
                      child: Center(
                        child: Text(
                          'Player ${index + 1}',
                          style: TextStyle(fontSize: playerFontSize),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            child: AspectRatio(
                                aspectRatio: 2.1,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (isAnyButtonOn) {
                                      if (isPressed[index]) {
                                        setState(() {
                                          incrementButtonCountBy(index, 1);
                                        });
                                      } else {
                                        setState(() {
                                          turnOffAll();
                                          isAnyButtonOn = false;
                                        });
                                      }
                                    } else {
                                      setState(() {
                                        turnOffAll();
                                        isPressed[index] = true;
                                        isAnyButtonOn = true;
                                      });
                                    }
                                  },
                                  child: Text(
                                    '${buttonCounts[index]}',
                                    style: TextStyle(
                                        fontSize: scoreFontSize,
                                        color: Colors.black),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    backgroundColor: () {
                                      if (playerCount % 2 != 0) {
                                        return Color.fromARGB(
                                            255, 255, 228, 168);
                                      } else {
                                        if (colorChanged)
                                          return colors[(index + 1) % 2];
                                        else
                                          return colors[index % 2];
                                      }
                                    }(),
                                  ),
                                )),
                          ),
                        ),
                        Expanded(
                            flex: 2,
                            child: Container(
                              color: Color.fromRGBO(37, 37, 38, 0.973),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (isAnyButtonOn) {
                                              if (isPressed[index]) {
                                                setState(() {
                                                  incrementButtonCountBy(
                                                      index, 2);
                                                });
                                              } else {
                                                setState(() {
                                                  turnOffAll();
                                                  isAnyButtonOn = false;
                                                });
                                              }
                                            } else {
                                              setState(() {
                                                turnOffAll();
                                                isPressed[index] = true;
                                                isAnyButtonOn = true;
                                              });
                                            }
                                          },
                                          child: Text(
                                            '+2',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: scoreBtnFontSize),
                                            softWrap: false,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                              ),
                                              backgroundColor:
                                                  Color.fromARGB(1, 2, 52, 161)
                                              // side: BorderSide(
                                              // width: 1.0, color: Colors.blue)
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (isAnyButtonOn) {
                                              if (isPressed[index]) {
                                                setState(() {
                                                  incrementButtonCountBy(
                                                      index, 3);
                                                });
                                              } else {
                                                setState(() {
                                                  turnOffAll();
                                                  isAnyButtonOn = false;
                                                });
                                              }
                                            } else {
                                              setState(() {
                                                turnOffAll();
                                                isPressed[index] = true;
                                                isAnyButtonOn = true;
                                              });
                                            }
                                          },
                                          child: Text(
                                            '+3',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: scoreBtnFontSize),
                                            softWrap: false,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                            backgroundColor:
                                                Color.fromARGB(1, 2, 52, 161),
                                            // side: BorderSide(
                                            // width: 1.0, color: Colors.blue)
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (isAnyButtonOn) {
                                              if (isPressed[index]) {
                                                setState(() {
                                                  incrementButtonCountBy(
                                                      index, 5);
                                                });
                                              } else {
                                                setState(() {
                                                  turnOffAll();
                                                  isAnyButtonOn = false;
                                                });
                                              }
                                            } else {
                                              setState(() {
                                                turnOffAll();
                                                isPressed[index] = true;
                                                isAnyButtonOn = true;
                                              });
                                            }
                                          },
                                          child: Text(
                                            '+5',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: scoreBtnFontSize,
                                            ),
                                            softWrap: false,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                              ),
                                              backgroundColor:
                                                  Color.fromARGB(1, 2, 52, 161)
                                              // side: BorderSide(
                                              // width: 1.0, color: Colors.blue)
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (isAnyButtonOn) {
                                              if (isPressed[index]) {
                                                setState(() {
                                                  decrementButtonCount(index);
                                                });
                                              } else {
                                                setState(() {
                                                  turnOffAll();
                                                  isAnyButtonOn = false;
                                                });
                                              }
                                            } else {
                                              setState(() {
                                                turnOffAll();
                                                isPressed[index] = true;
                                                isAnyButtonOn = true;
                                              });
                                            }
                                          },
                                          child: Text(
                                            '-1',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: scoreBtnFontSize,
                                            ),
                                            softWrap: false,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                            backgroundColor: Color.fromARGB(
                                                240, 245, 132, 12),
                                            // side: BorderSide(
                                            // width: 1.0, color: Colors.blue)
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSection(int index, int playerCount) {
    List<Color> colors = [
      Color.fromARGB(255, 255, 255, 255),
      Color.fromARGB(255, 255, 217, 0)
      // Color.fromARGB(255, 187, 61, 3),
      // Color.fromARGB(255, 202, 103, 2),
      // Color.fromARGB(255, 238, 155, 0),
      // Color.fromARGB(255, 0, 95, 115),
      // Color.fromARGB(255, 10, 147, 150),
      // Color.fromARGB(255, 233, 216, 166),
    ];

    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 6;
    double scoreBtnFontSize = screenHeight / 20;
    double playerFontSize = screenHeight / 30;
    double buttonSize = screenHeight / 4.5;

    return Center(
      child: AspectRatio(
        aspectRatio: 0.53,
        child: Container(
          margin: const EdgeInsets.only(left: 10.0, right: 10.0),
          height: MediaQuery.of(context).size.height / 2,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
            color: isPressed[index] ? Colors.lightBlue : Colors.transparent,

            // color: Color.fromRGBO(3, 35, 73, 1)
            // boxShadow: [
            // BoxShadow(
            // color: Colors.grey,
            // offset: const Offset(3.0, 3.0),
            // blurRadius: 2.0,
            // spreadRadius: 1.0,
            // )
            // ]
          ),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  color: Color.fromRGBO(37, 37, 38, 0.973),
                  child: Center(
                    child: Text(
                      'Player ${index + 1}',
                      style: TextStyle(fontSize: playerFontSize),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 10,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        child: AspectRatio(
                            aspectRatio: 1.6,
                            child: ElevatedButton(
                              onPressed: () {
                                if (isAnyButtonOn) {
                                  if (isPressed[index]) {
                                    setState(() {
                                      incrementButtonCountBy(index, 1);
                                    });
                                  } else {
                                    setState(() {
                                      turnOffAll();
                                      isAnyButtonOn = false;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    turnOffAll();
                                    isPressed[index] = true;
                                    isAnyButtonOn = true;
                                  });
                                }
                              },
                              child: Text(
                                '${buttonCounts[index]}',
                                style: TextStyle(
                                    fontSize: scoreFontSize,
                                    color: Colors.black),
                              ),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                backgroundColor: () {
                                  if (playerCount % 2 != 0) {
                                    return Color.fromARGB(255, 255, 228, 168);
                                  } else {
                                    if (colorChanged)
                                      return colors[(index + 1) % 2];
                                    else
                                      return colors[index % 2];
                                  }
                                }(),
                              ),
                            )),
                      ),
                    ),
                    Expanded(
                        flex: 3,
                        child: Container(
                          color: Color.fromRGBO(37, 37, 38, 0.973),
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (isAnyButtonOn) {
                                                if (isPressed[index]) {
                                                  setState(() {
                                                    incrementButtonCountBy(
                                                        index, 2);
                                                  });
                                                } else {
                                                  setState(() {
                                                    turnOffAll();
                                                    isAnyButtonOn = false;
                                                  });
                                                }
                                              } else {
                                                setState(() {
                                                  turnOffAll();
                                                  isPressed[index] = true;
                                                  isAnyButtonOn = true;
                                                });
                                              }
                                            },
                                            child: Text(
                                              '+2',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: scoreBtnFontSize),
                                              softWrap: false,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                ),
                                                backgroundColor: Color.fromARGB(
                                                    1, 2, 52, 161)
                                                // side: BorderSide(
                                                // width: 1.0, color: Colors.blue)
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (isAnyButtonOn) {
                                                if (isPressed[index]) {
                                                  setState(() {
                                                    incrementButtonCountBy(
                                                        index, 3);
                                                  });
                                                } else {
                                                  setState(() {
                                                    turnOffAll();
                                                    isAnyButtonOn = false;
                                                  });
                                                }
                                              } else {
                                                setState(() {
                                                  turnOffAll();
                                                  isPressed[index] = true;
                                                  isAnyButtonOn = true;
                                                });
                                              }
                                            },
                                            child: Text(
                                              '+3',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: scoreBtnFontSize),
                                              softWrap: false,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                              ),
                                              backgroundColor:
                                                  Color.fromARGB(1, 2, 52, 161),
                                              // side: BorderSide(
                                              // width: 1.0, color: Colors.blue)
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (isAnyButtonOn) {
                                                if (isPressed[index]) {
                                                  setState(() {
                                                    incrementButtonCountBy(
                                                        index, 5);
                                                  });
                                                } else {
                                                  setState(() {
                                                    turnOffAll();
                                                    isAnyButtonOn = false;
                                                  });
                                                }
                                              } else {
                                                setState(() {
                                                  turnOffAll();
                                                  isPressed[index] = true;
                                                  isAnyButtonOn = true;
                                                });
                                              }
                                            },
                                            child: Text(
                                              '+5',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: scoreBtnFontSize,
                                              ),
                                              softWrap: false,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                ),
                                                backgroundColor: Color.fromARGB(
                                                    1, 2, 52, 161)
                                                // side: BorderSide(
                                                // width: 1.0, color: Colors.blue)
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              if (isAnyButtonOn) {
                                                if (isPressed[index]) {
                                                  setState(() {
                                                    decrementButtonCount(index);
                                                  });
                                                } else {
                                                  setState(() {
                                                    turnOffAll();
                                                    isAnyButtonOn = false;
                                                  });
                                                }
                                              } else {
                                                setState(() {
                                                  turnOffAll();
                                                  isPressed[index] = true;
                                                  isAnyButtonOn = true;
                                                });
                                              }
                                            },
                                            child: Text(
                                              '-1',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: scoreBtnFontSize,
                                              ),
                                              softWrap: false,
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                              ),
                                              backgroundColor: Color.fromARGB(
                                                  240, 245, 132, 12),
                                              // side: BorderSide(
                                              // width: 1.0, color: Colors.blue)
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
