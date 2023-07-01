import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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
      title: 'Tablet App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TabletHomePage(),
      routes: {
        '/quickStart': (context) => QuickStartScreen(playerCount: 2, tabletNumber: tabletNumber,),
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
        title: Text('Tablet App'),
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
        child: Text(
          'Welcome to Tablet App!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

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
      final _TabletAppState tabletAppState = context.findAncestorStateOfType<_TabletAppState>()!;
      final int tabletNumber = tabletAppState.tabletNumber;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuickStartScreen(playerCount: count, tabletNumber: tabletNumber),
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

  void finishGame() {
    if (isTimerRunning) {
      stopTimer();
    }

    // 서버로 데이터 전송
    sendGameDataToServer(timerSeconds, widget.tabletNumber);
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
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  (widget.playerCount / 2).ceil(),
                  (index) => _buildPlayerSection(index),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Timer',
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(height: 16),
                    Text(
                      formattedTime,
                      style: TextStyle(fontSize: 40),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: startTimer,
                          child: Text('Start'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: stopTimer,
                          child: Text('Stop'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: resetTimer,
                          child: Text('Reset'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: finishGame, // Finish 버튼 클릭 시 데이터 전송
                      child: Text('Finish'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  (widget.playerCount / 2).floor(),
                  (index) => _buildPlayerSection(index + (widget.playerCount / 2).ceil()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSection(int index) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Player ${index + 1}',
          style: TextStyle(fontSize: 20),
        ),
        Text(
          'Count: ${buttonCounts[index]}',
          style: TextStyle(fontSize: 20),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => incrementButtonCountBy(index, 1),
              child: Text('+1'),
            ),
            ElevatedButton(
              onPressed: () => incrementButtonCountBy(index, 2),
              child: Text('+2'),
            ),
            ElevatedButton(
              onPressed: () => incrementButtonCountBy(index, 3),
              child: Text('+3'),
            ),
            ElevatedButton(
              onPressed: () => incrementButtonCountBy(index, 5),
              child: Text('+5'),
            ),
            ElevatedButton(
              onPressed: () => decrementButtonCount(index),
              child: Text('-1'),
            ),
            
          ],
        ),
      ],
    ),
  );
}

void sendGameDataToServer(int playTime, int tabletNumber) {
    // playTime(플레이 시간)과 tabletNumber(테이블 번호)를 서버로 전송하는 로직을 구현해야 합니다.
    // 이 부분은 실제 서버와의 통신 코드로 대체되어야 합니다.
    print('Sending game data to server...');
    print('Play Time: $playTime seconds');
    print('Tablet Number: $tabletNumber');
    // 서버로 데이터 전송하는 함수 호출
  }

}


void sendTimerDataToServer(int elapsedSeconds) async {
    String url = 'https://your-server-url.com/endpoint'; // 서버의 엔드포인트 URL로 변경해주세요
    Map<String, dynamic> data = {
      'elapsed_seconds': elapsedSeconds,
    };

    try {
      var response = await http.post(Uri.parse(url), body: data);
      if (response.statusCode == 200) {
        // 전송 성공
        print('Timer data sent to server successfully');
      } else {
        // 전송 실패
        print('Failed to send timer data to server');
      }
    } catch (e) {
      // 에러 처리
      print('Error: $e');
    }
}

class SettingScreen extends StatefulWidget {

  final int tabletNumber;
  final Function(int) onTabletNumberChanged;

  SettingScreen({required this.tabletNumber, required this.onTabletNumberChanged});

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
  void _sendDataToServer() {
    // 데이터 서버로 전송하는 로직 구현
    // tabletNumber와 게임 플레이 시간 등의 데이터를 서버로 전송
    // 이 부분은 실제 서버와의 통신 코드로 대체되어야 합니다.
    print('Sending data to server...');
    print('Tablet Number: $selectedTabletNumber');
    // 게임 플레이 시간 데이터 등을 서버로 전송하는 함수 호출
  }
}
