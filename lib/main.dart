import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'global.dart';
import 'quick.dart';
import 'setting.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

// import 'package:audioplayers/audioplayers.dart';

void main() {
  VideoPlayerMediaKit.ensureInitialized(
    macOS: true,
    windows: true,
    linux: true,
  );
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
        '/quickStart': (context) => QuickStartScreen(playerCount: 2),
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
        child: InkWell(
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
              border: Border.all(color: Colors.white, width: 2), // 하얀 테두리 추가
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // void _showQuickStart(BuildContext context) {
  // final _TabletAppState tabletAppState =
  // context.findAncestorStateOfType<_TabletAppState>()!;
  // final int tabletNumber = tabletAppState.tabletNumber;

  // Navigator.push(
  // context,
  // MaterialPageRoute(
  // builder: (context) =>
  // QuickStartScreen(playerCount: 2, tabletNumber: tabletNumber),
  // ),
  // );
  // }

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
      final _TabletAppState tabletAppState =
          context.findAncestorStateOfType<_TabletAppState>()!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuickStartScreen(playerCount: count),
        ),
      );
    }
  }
}
