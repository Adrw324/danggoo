import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(TabletApp());
}

class TabletApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tablet App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TabletHomePage(),
      routes: {
        '/quickStart': (context) => QuickStartScreen(),
        '/setting': (context) => SettingScreen(),
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
                Navigator.pushNamed(context, '/quickStart');
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
}

class QuickStartScreen extends StatefulWidget {
  @override
  _QuickStartScreenState createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends State<QuickStartScreen> {
  late Timer _timer;
  bool isTimerRunning = false;
  int timerSeconds = 0;
  String formattedTime = '00:00:00';
  int button1Count = 0;
  int button2Count = 0;

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

  void incrementButton1Count() {
    setState(() {
      button1Count++;
    });
  }

  void incrementButton2Count() {
    setState(() {
      button2Count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quick Start'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formattedTime,
              style: TextStyle(fontSize: 40),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isTimerRunning ? stopTimer : startTimer,
                  child: Text(
                    isTimerRunning ? 'Stop Timer' : 'Start Timer',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: resetTimer,
                  child: Text(
                    'Reset Timer',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Button 1 Count: $button1Count',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: incrementButton1Count,
              child: Text(
                'Button 1',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Button 2 Count: $button2Count',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: incrementButton2Count,
              child: Text(
                'Button 2',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
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
}


class SettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setting'),
      ),
      body: Center(
        child: Text(
          'Setting Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
