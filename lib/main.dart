import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';

class Game {
  final int tableNum;
  final String date;
  final String start;
  final String end;
  final int playtime;
  final double fee;
  final bool finished;

  Game(
      {required this.tableNum,
      required this.start,
      required this.end,
      required this.playtime,
      required this.fee,
      required this.finished,
      required this.date});

  Map<String, dynamic> toJson() {
    return {
      'Table_Num': tableNum,
      'Date': date,
      'Start': start,
      'End': end,
      'Playtime': playtime,
      'Fee': fee,
      'Finished': finished
    };
  }
}

class GameDataSender {
  final String serverUrl = 'localhost:5157'; // 서버의 URL로 변경해주세요

  Future<void> sendGameData(Game game) async {
    final apiUrl = Uri.http('$serverUrl', '/Games/Receive');
    final headers = {
      'Content-Type': 'application/json',
      "Access-Control_Allow_Origin": "*",
      'Accept': '*/*'
    };
    final gameData = game.toJson();

    try {
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: jsonEncode(gameData),
      );

      if (response.statusCode == 200) {
        print('Game data sent successfully');
      } else {
        print('Failed to send game data');
      }
    } catch (e) {
      print('Error sending game data: $e');
    }
  }
}

void main() {
  runApp(TabletApp());
}

class TabletApp extends StatefulWidget {
  @override
  State<TabletApp> createState() => _TabletAppState();
}

class _TabletAppState extends State<TabletApp> {
  int tabletNumber = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nice Q',
      theme: ThemeData.dark(),
      home: TabletHomePage(),
      routes: {
        '/quickStart': (context) => QuickStartScreen(
              playerCount: 2,
              tabletNumber: tabletNumber,
            ),
        '/setting': (context) => SettingScreen(
              tabletNumber: tabletNumber,
              onTabletNumberChanged: (newTabletNumber) {
                setState(() {
                  tabletNumber = newTabletNumber;
                });
              },
            ),
      },
    );
  }
}

class TabletHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nice Q'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Navigation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Quick Start'),
              onTap: () {
                Navigator.pop(context);
                _showPlayerCountDialog(context);
              },
            ),
            ListTile(
              title: Text('Setting'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/setting');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/quickStart');
          },
          child: Container(
            width: 200,
            height: 200,
            child: Center(
              child: Text(
                'Quick Start',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2), // 하얀 테두리 추가
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // void _showQuickStart(BuildContext context) {
  //   final _TabletAppState tabletAppState =
  //       context.findAncestorStateOfType<_TabletAppState>()!;
  //   final int tabletNumber = tabletAppState.tabletNumber;

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) =>
  //           QuickStartScreen(playerCount: 2, tabletNumber: tabletNumber),
  //     ),
  //   );
  // }

  Future<void> _showPlayerCountDialog(BuildContext context) async {
    final int? count = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Player Count'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (index) {
              final playerCount = index + 2;
              return ListTile(
                title: Text('$playerCount Players'),
                onTap: () {
                  Navigator.of(context).pop(playerCount);
                },
              );
            }),
          ),
        );
      },
    );

    if (count != null) {
      final _TabletAppState tabletAppState =
          context.findAncestorStateOfType<_TabletAppState>()!;
      final int tabletNumber = tabletAppState.tabletNumber;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              QuickStartScreen(playerCount: count, tabletNumber: tabletNumber),
        ),
      );
    }
  }
}

class QuickStartScreen extends StatefulWidget {
  final int playerCount;
  final int tabletNumber;

  QuickStartScreen({required this.playerCount, required this.tabletNumber});

  @override
  _QuickStartScreenState createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends State<QuickStartScreen> {
  late Timer _timer;
  bool isTimerRunning = false;
  int timerSeconds = 0;
  String formattedTime = '00:00:00';
  List<int> buttonCounts = [];
  DateTime gameStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 플레이어 수에 맞게 버튼 카운트 초기화
    buttonCounts = List<int>.filled(widget.playerCount, 0);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void startGame() {
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
                _startGameConfirmed();
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

  void _startGameConfirmed() {
    DateTime today = DateTime.now();
    gameStartTime = DateTime.now();

    Game game = Game(
      tableNum: 1,
      date: today.toIso8601String(),
      start: gameStartTime.toIso8601String(),
      end: gameStartTime.toIso8601String(),
      playtime: 0,
      fee: 0,
      finished: false,
    );

    GameDataSender gameDataSender = GameDataSender();
    gameDataSender.sendGameData(game);

    startTimer();
  }

  void finishGame() {
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
                _finishGameConfirmed();
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

  void _finishGameConfirmed() {
    DateTime today = DateTime.now();
    DateTime end = DateTime.now();

    Duration timeDifference = end.difference(gameStartTime);

    int minutesDifference = timeDifference.inMinutes;

    Game game = Game(
      tableNum: 1,
      date: today.toIso8601String(),
      start: gameStartTime.toIso8601String(),
      end: end.toIso8601String(),
      playtime: minutesDifference,
      fee: minutesDifference * 30 / 60,
      finished: true,
    );

    GameDataSender gameDataSender = GameDataSender();
    gameDataSender.sendGameData(game);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quick Start'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  (widget.playerCount / 2).ceil(),
                  (index) => _buildPlayerSection(index, widget.playerCount),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Playtime',
                      style: TextStyle(fontSize: 60),
                    ),
                    SizedBox(height: 16),
                    Text(
                      formattedTime,
                      style: TextStyle(fontSize: 60),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: startGame,
                          child: Text('Start'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: finishGame, // Finish 버튼 클릭 시 데이터 전송
                          child: Text('Finish'),
                        ),
                      ],
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
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  (widget.playerCount / 2).floor(),
                  (index) => _buildPlayerSection(
                      index + (widget.playerCount / 2).ceil(),
                      widget.playerCount),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSection(int index, int playerCount) {
    return Container(
      height: MediaQuery.of(context).size.height / 4.3,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              child: Text(
                'Player ${index + 1}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: OutlinedButton(
                            onPressed: () => incrementButtonCountBy(index, 2),
                            child: Text('+2'),
                            style: OutlinedButton.styleFrom(
                                side:
                                    BorderSide(width: 1.0, color: Colors.blue)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: OutlinedButton(
                            onPressed: () => incrementButtonCountBy(index, 3),
                            child: Text('+3'),
                            style: OutlinedButton.styleFrom(
                                side:
                                    BorderSide(width: 1.0, color: Colors.blue)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  child: AspectRatio(
                      aspectRatio: 1,
                      child: OutlinedButton(
                        onPressed: () => incrementButtonCountBy(index, 1),
                        child: Text(
                          '${buttonCounts[index]}',
                          style: TextStyle(fontSize: 80, color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                            side: BorderSide(width: 3.0, color: Colors.white)),
                      )),
                ),
                Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: OutlinedButton(
                            onPressed: () => incrementButtonCountBy(index, 5),
                            child: Text('+5'),
                            style: OutlinedButton.styleFrom(
                                side:
                                    BorderSide(width: 1.0, color: Colors.blue)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: OutlinedButton(
                            onPressed: () => decrementButtonCount(index),
                            child: Text('-1'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: BorderSide(
                                    width: 1.0, color: Colors.orange)),
                          ),
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
    );
  }
}

class SettingScreen extends StatefulWidget {
  final int tabletNumber;
  final Function(int) onTabletNumberChanged;

  SettingScreen(
      {required this.tabletNumber, required this.onTabletNumberChanged});

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int selectedTabletNumber = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setting'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tablet Number',
              style: TextStyle(fontSize: 20),
            ),
            DropdownButton<int>(
              value: selectedTabletNumber,
              onChanged: (int? newValue) {
                setState(() {
                  selectedTabletNumber = newValue!;
                });
              },
              items: <int>[1, 2, 3].map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('Tablet $value'),
                );
              }).toList(),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onTabletNumberChanged(selectedTabletNumber);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
