import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'global.dart';
import 'quick.dart';
import 'setting.dart';

// import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameData(),
      child: TabletApp(),
    ),
  );
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
      title: 'NICE Q',
      theme: ThemeData.dark(),
      home: TabletHomePage(),
      routes: {
        '/quickStart': (context) => QuickStartScreen(
              playerCount: 2,
              handicabScores: [0, 0],
            ),
        '/setting': (context) => SettingScreen()
      },
    );
  }
}

class TabletHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                _showPlayerCountDialog(context);
                // Navigator.pushNamed(context, '/quickStart');
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
                  border:
                      Border.all(color: Colors.white, width: 2), // 하얀 테두리 추가
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
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
            children: List.generate(5, (index) {
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
      // Show dialog to set handi-tab scores for each player
      _showHandiTabScoreDialog(context, count);
    }
  }

  Future<void> _showHandiTabScoreDialog(
      BuildContext context, int playerCount) async {
    List<int> handicabScores =
        List.filled(playerCount, 0); // Initialize scores for each player to 0

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Handicab Scores'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(playerCount, (index) {
              return ListTile(
                title: Text('Player ${index + 1}'),
                contentPadding: EdgeInsets.all(0),
                trailing: Container(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      handicabScores[index] = int.tryParse(value) ?? 0;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Score',
                    ),
                  ),
                ),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to QuickStartScreen with playerCount and handiTabScores
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuickStartScreen(
                      playerCount: playerCount,
                      handicabScores: handicabScores,
                    ),
                  ),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
