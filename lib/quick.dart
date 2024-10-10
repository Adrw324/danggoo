import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'global.dart';
import 'services/web_socket_service.dart';
import 'video-manager.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'fullscreen.dart';

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
  final List<int> handicabScores;
  final bool isHandicap;
  final WebSocketService webSocketService;

  QuickStartScreen({
    required this.playerCount,
    required this.handicabScores,
    required this.isHandicap,
    required this.webSocketService,
  });

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

  late StreamSubscription _messageSubscription;
  // bool isAnyButtonOn = false;
  // List<bool> isPressed = [false, false, false, false, false, false];

  late VideoManager videoManager;

  bool _isLoading = true;

  bool isPlayingStartSound = false;

  Soundpool pool = Soundpool(streamType: StreamType.notification);
  late List<int> soundId = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 10;
    double scoreBtnFontSize = screenHeight / 14;
    double PlaytimeFontSize = screenHeight / 10;

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
            // turnOffAll();
            // isAnyButtonOn = false;
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: widget.playerCount < 5
                      ? List.generate((widget.playerCount / 2).ceil(), (index) {
                          final playerIndex = index * 2;
                          if (widget.playerCount == 2)
                            return _buildPlayerSection(
                                playerIndex,
                                widget.playerCount,
                                widget.handicabScores,
                                widget.isHandicap);
                          else
                            return _buildPlayerSection3(
                                playerIndex,
                                widget.playerCount,
                                widget.handicabScores,
                                widget.isHandicap);
                        })
                      : List.generate((widget.playerCount / 2).ceil(), (index) {
                          final playerIndex = index * 2;
                          return _buildPlayerSection5(
                              playerIndex,
                              widget.playerCount,
                              widget.handicabScores,
                              widget.isHandicap);
                        }),
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Container(
                decoration: BoxDecoration(
                    // border: Border.all(color: Colors.black),
                    ),
                child: Center(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 10,
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
                                          child: Stack(children: [
                                            Video(
                                              controller:
                                                  videoManager.controller,
                                              controls: NoVideoControls,
                                            ),
                                            CustomVideoControls(
                                                controller:
                                                    videoManager.controller),
                                          ]),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Expanded(
                      //   flex: 1,
                      //   child: Row(
                      //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      //     children: [
                      //       TextButton(
                      //         onPressed: () async {
                      //           await videoManager.player.seek(
                      //               videoManager.player.state.position -
                      //                   Duration(seconds: 10));
                      //         },
                      //         child: Icon(Icons.replay_10,
                      //             size: 35, color: Colors.white),
                      //       ),
                      //       TextButton(
                      //         onPressed: () async {
                      //           await videoManager.player.seek(
                      //               videoManager.player.state.position +
                      //                   Duration(seconds: 10));
                      //         },
                      //         child: Icon(Icons.forward_10,
                      //             size: 35, color: Colors.white),
                      //       ),
                      //       // TextButton(
                      //       //   onPressed: ,
                      //       //   child: Icon(Icons.update,
                      //       //       size: 35, color: Colors.white),
                      //       // ),
                      //       TextButton(
                      //         onPressed: _showResetConfirmationDialog,
                      //         child: Text(
                      //           'Reset',
                      //           style:
                      //               TextStyle(color: Colors.teal, fontSize: 20),
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                                onPressed: () async {
                                  await videoManager.adjustDelay(1);
                                  setState(() {});
                                },
                                icon: Text("1 SEC SLOWER",
                                    style: TextStyle(fontSize: 20))),
                            IconButton(
                              onPressed: () async {
                                await videoManager.adjustDelay(-1);
                                setState(() {});
                              },
                              icon: Text("1 SEC FASTER",
                                  style: TextStyle(fontSize: 20)),
                            ),
                            IconButton(
                              onPressed: _reloadVideo,
                              icon: Text(
                                "RELOAD",
                                style: TextStyle(
                                    color: Colors.orange, fontSize: 20),
                              ),
                            ),
                            Text(
                              "Current Delay: ${videoManager.currentDelay.inSeconds}s",
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                    Padding(
                                      padding: const EdgeInsets.all(60.0),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Color.fromRGBO(37, 37, 38, 0.973),
                                        ),
                                        onPressed: () => startGame(
                                            Provider.of<GameData>(context,
                                                listen: false)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Container(
                                              child: Center(
                                                  child: Text('START',
                                                      style: TextStyle(
                                                          fontSize: 45,
                                                          color:
                                                              Colors.white)))),
                                        ),
                                      ),
                                    ),
                                  if (isGameStarted)
                                    Padding(
                                      padding: const EdgeInsets.all(60.0),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        onPressed: () => finishGame((Provider.of<
                                                GameData>(context,
                                            listen:
                                                false))), // Finish 버튼 클릭 시 데이터 전송
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Container(
                                              child: Center(
                                                  child: Text('FINISH',
                                                      style: TextStyle(
                                                          fontSize: 50,
                                                          color:
                                                              Colors.white)))),
                                        ),
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: widget.playerCount < 5
                      ? List.generate((widget.playerCount / 2).floor(),
                          (index) {
                          final playerIndex = index * 2 + 1;
                          if (widget.playerCount == 2)
                            return _buildPlayerSection(
                                playerIndex,
                                widget.playerCount,
                                widget.handicabScores,
                                widget.isHandicap);
                          else
                            return _buildPlayerSection3(
                                playerIndex,
                                widget.playerCount,
                                widget.handicabScores,
                                widget.isHandicap);
                        })
                      : List.generate((widget.playerCount / 2).floor(),
                          (index) {
                          final playerIndex = index * 2 + 1;
                          return _buildPlayerSection5(
                              playerIndex,
                              widget.playerCount,
                              widget.handicabScores,
                              widget.isHandicap);
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
    _messageSubscription =
        widget.webSocketService.messageStream.listen((message) {
      if (message == 'ForceStartGame') {
        if (!isTimerRunning) {
          print("Forcing game start");
          _startGameWithoutConfirmation(
              Provider.of<GameData>(context, listen: false));
        }
      } else if (message == 'ForceEndGame') {
        if (isTimerRunning) {
          print("Forcing game end");
          _finishGameWithoutConfirmation(
              Provider.of<GameData>(context, listen: false));
        }
      }
    });

    buttonCounts = List<int>.filled(widget.playerCount, 0);

    final gameData = Provider.of<GameData>(context, listen: false);

    videoManager = VideoManager(gameData);
    _initializeVideo();

    _settingButtonSound();

    print('HANDICAPS ' + '${widget.handicabScores}');
  }

  Future<void> _initializeVideo() async {
    final gameData = Provider.of<GameData>(context, listen: false);
    try {
      await videoManager.initialize(gameData.camera_uri);
      await videoManager.play(); //
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Video initialization error: $e');
      // 사용자에게 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비디오 초기화 중 오류가 발생했습니다.')),
        );
      }
    }
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

  @override
  Future<void> dispose() async {
    videoManager.dispose();
    pool.dispose();
    _messageSubscription.cancel();
    if (_timer != null) {
      _timer.cancel();
    }
    print('Disposed!');

    super.dispose();
  }

  Future<void> _startGameIfNotStarted(GameData gameData) async {
    if (!isGameStarted) {
      setState(() {
        isGameStarted = true;
        isPlayingStartSound = true;
      });
      await pool.play(soundId[11]);
      setState(() {
        isPlayingStartSound = false;
      });
      await Future.delayed(Duration(milliseconds: 500));
      _startGameConfirmed(gameData);
    }
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

  void _startGameConfirmed(GameData gameData) async {
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

    await pool.play(soundId[11]);

    startTimer();
    // widget.webSocketService.sendMessage({
    //   'type': 'GameStarted',
    //   'tableId': table,
    // });
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

    finish();
    // widget.webSocketService.sendMessage({
    //   'type': 'GameEnded',
    //   'tableId': table,
    // });
    Navigator.pop(context);
  }

  void _startGameWithoutConfirmation(GameData gameData) {
    setState(() {
      isGameStarted = true;
    });
    _startGameConfirmed(gameData);
  }

  void _finishGameWithoutConfirmation(GameData gameData) {
    setState(() {
      isGameStarted = false;
    });
    _finishGameConfirmed(gameData);
  }

  void startTimer() {
    if (!isTimerRunning) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            timerSeconds++;
            formattedTime = _formatTime(timerSeconds);
          });
        }
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

  Future<void> incrementButtonCountBy(int index, int count) async {
    await _startGameIfNotStarted(Provider.of<GameData>(context, listen: false));
    setState(() {
      buttonCounts[index] += count;
    });

    if (!isPlayingStartSound) {
      switch (count) {
        case 1:
          await pool.play(soundId[7]); // onep.mp3
          break;
        case 2:
          await pool.play(soundId[8]); // twop.mp3
          break;
        case 3:
          await pool.play(soundId[9]); // threep.mp3
          break;
        case 5:
          await pool.play(soundId[10]); // fanfare.mp3
          break;
      }
    }
  }

  Future<void> decrementButtonCount(int index) async {
    _startGameIfNotStarted(Provider.of<GameData>(context, listen: false));
    setState(() {
      buttonCounts[index]--;
    });
  }

  // void turnOffAll() {
  //   isPressed[0] = false;
  //   isPressed[1] = false;
  //   isPressed[2] = false;
  //   isPressed[3] = false;
  //   isPressed[4] = false;
  //   isPressed[5] = false;
  // }

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

  Widget _buildPlayerSection5(
      int index, int playerCount, List<int> handicabScores, bool isHandicap) {
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

    Future<void> checkWinner(
        int buttonCount, int handicap, int index, bool isHandicap) async {
      if (!isHandicap) return;
      int remainingPoints = handicap - buttonCount;
      if (remainingPoints >= 1 && remainingPoints <= 5) {
        await pool.play(soundId[remainingPoints]);
      } else if (buttonCount >= handicap) {
        await pool.play(soundId[6]); // winner.mp3
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text('PLAYER ${index + 1} Win !!!',
                    style: TextStyle(fontSize: 100)),
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('CLOSE', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      }
    }

    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 16;
    double scoreBtnFontSize = screenHeight / 55;
    double playerFontSize = screenHeight / 40;
    return Center(
      child: AspectRatio(
        aspectRatio: 1.08,
        child: Container(
          margin: const EdgeInsets.only(left: 10.0, right: 10.0),
          height: MediaQuery.of(context).size.height / 5,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
            // color: isPressed[index] ? Colors.lightBlue : Colors.transparent,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(37, 37, 38, 0.973),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Container(
                          child: AspectRatio(
                              aspectRatio: 2.1,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    incrementButtonCountBy(index, 1);
                                    checkWinner(
                                        buttonCounts[index],
                                        handicabScores[index],
                                        index,
                                        isHandicap);
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'PLAYER ${index + 1}',
                                            style: TextStyle(
                                                fontSize: playerFontSize,
                                                color: Colors.black),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${buttonCounts[index]}',
                                        style: TextStyle(
                                            fontSize: scoreFontSize,
                                            color: Colors.black),
                                      ),
                                      if (isHandicap)
                                        Padding(
                                          padding: const EdgeInsets.all(0),
                                          child: Text(
                                            '${handicabScores[index]}',
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: playerFontSize * 1.3),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      // borderRadius: BorderRadius.circular(5.0),
                                      ),
                                  backgroundColor: () {
                                    if (playerCount % 2 != 0) {
                                      return Color.fromARGB(255, 255, 255, 255);
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
                                    padding: const EdgeInsets.all(1),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            incrementButtonCountBy(index, 2);
                                            checkWinner(
                                                buttonCounts[index],
                                                handicabScores[index],
                                                index,
                                                isHandicap);
                                          });
                                        },
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            child: Text(
                                              '+2',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: scoreBtnFontSize,
                                              ),
                                            ),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(),
                                          backgroundColor:
                                              Color.fromARGB(1, 2, 52, 161),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            incrementButtonCountBy(index, 3);
                                            checkWinner(
                                                buttonCounts[index],
                                                handicabScores[index],
                                                index,
                                                isHandicap);
                                          });
                                        },
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            child: Text(
                                              '+3',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: scoreBtnFontSize,
                                              ),
                                            ),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(),
                                          backgroundColor:
                                              Color.fromARGB(1, 2, 52, 161),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            incrementButtonCountBy(index, 5);
                                            checkWinner(
                                                buttonCounts[index],
                                                handicabScores[index],
                                                index,
                                                isHandicap);
                                          });
                                        },
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            child: Text(
                                              '+5',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: scoreBtnFontSize,
                                              ),
                                            ),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(),
                                          backgroundColor:
                                              Color.fromARGB(1, 2, 52, 161),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(1.0),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            decrementButtonCount(index);
                                            checkWinner(
                                                buttonCounts[index],
                                                handicabScores[index],
                                                index,
                                                isHandicap);
                                          });
                                        },
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            child: Text(
                                              '-1',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: scoreBtnFontSize,
                                              ),
                                            ),
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(),
                                          backgroundColor: Colors.red,
                                          padding: EdgeInsets.zero,
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
    );
  }

  Widget _buildPlayerSection3(
      int index, int playerCount, List<int> handicabScores, bool isHandicap) {
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

    Future<void> checkWinner(
        int buttonCount, int handicap, int index, bool isHandicap) async {
      if (!isHandicap) return;
      int remainingPoints = handicap - buttonCount;
      if (remainingPoints >= 1 && remainingPoints <= 5) {
        await pool.play(soundId[remainingPoints]);
      } else if (buttonCount >= handicap) {
        await pool.play(soundId[6]); // winner.mp3
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text('PLAYER ${index + 1} Win !!!',
                    style: TextStyle(fontSize: 100)),
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('CLOSE', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      }
    }

    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 10;
    double scoreBtnFontSize = screenHeight / 50;
    double playerFontSize = screenHeight / 30;
    double buttonSize = screenHeight / 4.5;

    return Center(
      child: AspectRatio(
        aspectRatio: 0.7,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
            // color: isPressed[index] ? Colors.lightBlue : Colors.transparent,
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
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Container(
                            child: AspectRatio(
                                aspectRatio: 2.1,
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      incrementButtonCountBy(index, 1);
                                      checkWinner(
                                          buttonCounts[index],
                                          handicabScores[index],
                                          index,
                                          isHandicap);
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 20), // 위아래 패딩 추가
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'PLAYER ${index + 1}',
                                          style: TextStyle(
                                            fontSize: playerFontSize,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 2), // 아주 작은 간격
                                        Text(
                                          '${buttonCounts[index]}',
                                          style: TextStyle(
                                            fontSize: scoreFontSize,
                                            color: Colors.black,
                                          ),
                                        ),

                                        if (isHandicap)
                                          Text(
                                            '${handicabScores[index]}',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: playerFontSize * 1.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        // borderRadius: BorderRadius.circular(5.0),
                                        ),
                                    backgroundColor: () {
                                      if (playerCount % 2 != 0) {
                                        return Color.fromARGB(
                                            255, 255, 255, 255);
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
                                      padding: const EdgeInsets.all(1),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              incrementButtonCountBy(index, 2);
                                              checkWinner(
                                                  buttonCounts[index],
                                                  handicabScores[index],
                                                  index,
                                                  isHandicap);
                                            });
                                          },
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '+2',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: scoreBtnFontSize,
                                                ),
                                              ),
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(),
                                            backgroundColor:
                                                Color.fromARGB(1, 2, 52, 161),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.0),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              incrementButtonCountBy(index, 3);
                                              checkWinner(
                                                  buttonCounts[index],
                                                  handicabScores[index],
                                                  index,
                                                  isHandicap);
                                            });
                                          },
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '+3',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: scoreBtnFontSize,
                                                ),
                                              ),
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(),
                                            backgroundColor:
                                                Color.fromARGB(1, 2, 52, 161),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.0),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              incrementButtonCountBy(index, 5);
                                              checkWinner(
                                                  buttonCounts[index],
                                                  handicabScores[index],
                                                  index,
                                                  isHandicap);
                                            });
                                          },
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '+5',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: scoreBtnFontSize,
                                                ),
                                              ),
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(),
                                            backgroundColor:
                                                Color.fromARGB(1, 2, 52, 161),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(1.0),
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              decrementButtonCount(index);
                                              checkWinner(
                                                  buttonCounts[index],
                                                  handicabScores[index],
                                                  index,
                                                  isHandicap);
                                            });
                                          },
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Container(
                                              padding: EdgeInsets.all(8),
                                              child: Text(
                                                '-1',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: scoreBtnFontSize,
                                                ),
                                              ),
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(),
                                            backgroundColor: Colors.red,
                                            padding: EdgeInsets.zero,
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

  Widget _buildPlayerSection(
      int index, int playerCount, List<int> handicabScores, bool isHandicap) {
    List<Color> colors = [
      Color.fromARGB(255, 255, 255, 255),
      Color.fromARGB(255, 255, 217, 0)
    ];

    Future<void> checkWinner(
        int buttonCount, int handicap, int index, bool isHandicap) async {
      if (!isHandicap) return;
      int remainingPoints = handicap - buttonCount;
      if (remainingPoints >= 1 && remainingPoints <= 5) {
        await pool.play(soundId[remainingPoints]);
      } else if (buttonCount >= handicap) {
        await pool.play(soundId[6]); // winner.mp3
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text('PLAYER ${index + 1} Win !!!',
                    style: TextStyle(fontSize: 100)),
              ),
              actions: [
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('CLOSE', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      }
    }

    double screenHeight = MediaQuery.of(context).size.height;
    double scoreFontSize = screenHeight / 8;
    double scoreBtnFontSize = screenHeight / 20;
    double playerFontSize = screenHeight / 25;
    double handicapFontSize = playerFontSize * 2;
    double buttonSize = screenHeight / 4.5;

    return Center(
      child: AspectRatio(
        aspectRatio: 0.37,
        child: Container(
          margin: const EdgeInsets.only(left: 10.0, right: 10.0),
          height: MediaQuery.of(context).size.height / 2,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
            // color: isPressed[index] ? Colors.lightBlue : Colors.transparent,
          ),
          child: Column(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        incrementButtonCountBy(index, 1);
                        checkWinner(buttonCounts[index], handicabScores[index],
                            index, isHandicap);
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'PLAYER ${index + 1}',
                              style: TextStyle(
                                  fontSize: playerFontSize,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                        Text(
                          '${buttonCounts[index]}',
                          style: TextStyle(
                              fontSize: scoreFontSize, color: Colors.black),
                        ),
                        if (isHandicap)
                          Padding(
                            padding: const EdgeInsets.all(0),
                            child: Text(
                              '${handicabScores[index]}',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: handicapFontSize,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(),
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
                  ),
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
                                      setState(() {
                                        incrementButtonCountBy(index, 2);
                                        checkWinner(
                                            buttonCounts[index],
                                            handicabScores[index],
                                            index,
                                            isHandicap);
                                      });
                                    },
                                    child: FittedBox(
                                      fit: BoxFit.fill,
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        child: Text(
                                          '+2',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: scoreBtnFontSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(),
                                      backgroundColor:
                                          Color.fromARGB(1, 2, 52, 161),
                                      padding: EdgeInsets.zero,
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
                                      setState(() {
                                        incrementButtonCountBy(index, 3);
                                        checkWinner(
                                            buttonCounts[index],
                                            handicabScores[index],
                                            index,
                                            isHandicap);
                                      });
                                    },
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        child: Text(
                                          '+3',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: scoreBtnFontSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(),
                                      backgroundColor:
                                          Color.fromARGB(1, 2, 52, 161),
                                      padding: EdgeInsets.zero,
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
                                      setState(() {
                                        incrementButtonCountBy(index, 5);
                                        checkWinner(
                                            buttonCounts[index],
                                            handicabScores[index],
                                            index,
                                            isHandicap);
                                      });
                                    },
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        child: Text(
                                          '+5',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: scoreBtnFontSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(),
                                      backgroundColor:
                                          Color.fromARGB(1, 2, 52, 161),
                                      padding: EdgeInsets.zero,
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
                                      setState(() {
                                        decrementButtonCount(index);
                                        checkWinner(
                                            buttonCounts[index],
                                            handicabScores[index],
                                            index,
                                            isHandicap);
                                      });
                                    },
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        child: Text(
                                          '-1',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: scoreBtnFontSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(),
                                      backgroundColor: Colors.red,
                                      padding: EdgeInsets.zero,
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
