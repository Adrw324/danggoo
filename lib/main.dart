import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'global.dart';
import 'quick.dart';
import 'setting.dart';
import 'match.dart';
import 'services/web_socket_service.dart';
import 'package:media_kit/media_kit.dart';
import 'playerSelection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await initApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => GameData()),
        ChangeNotifierProvider(
            create: (context) => MatchData()), // MatchData provider 추가
      ],
      child: TabletApp(),
    ),
  );
}

class TabletApp extends StatefulWidget {
  @override
  State<TabletApp> createState() => _TabletAppState();
}

class _TabletAppState extends State<TabletApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NICE Q',
      theme: ThemeData.dark(),
      home: TabletHomePage(),
      routes: {
        '/setting': (context) => SettingScreen(),
        '/match': (context) => PlayerSelectionScreen(),
      },
    );
  }
}

Future<void> initApp() async {
  final gameData = GameData();
  await gameData.loadGameData();
}

class TabletHomePage extends StatefulWidget {
  @override
  _TabletHomePageState createState() => _TabletHomePageState();
}

class _TabletHomePageState extends State<TabletHomePage> {
  List<int> handicabScores = [];
  late WebSocketService _webSocketService;
  String _status = "Waiting...";
  String _latestMessage = "";

  late final serverUrl; // 설정 파일에서 읽거나 사용자 입력으로 받을 수 있음

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWebSocket();
    });
  }

  Future<void> _initializeWebSocket() async {
    final gameData = Provider.of<GameData>(context, listen: false);
    await gameData.loadGameData();

    _webSocketService = WebSocketService(gameData.manager_uri, gameData);
    _webSocketService.statusStream.listen((status) {
      setState(() {
        _status = status;
      });
    });
    _webSocketService.messageStream.listen((message) {
      setState(() {
        _latestMessage = message;
      });
    });
    await _webSocketService.connect();
  }

  @override
  void dispose() {
    _webSocketService.close();
    super.dispose();
  }

  Future<void> _retryConnection() async {
    setState(() {
      _status = "Reconnecting...";
    });

    try {
      await _webSocketService.retryConnection();
    } catch (e) {
      print("Error during reconnection: $e");
      setState(() {
        _status = "Reconnection failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Current status in build: $_status");
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 1, 1, 1),
      appBar: AppBar(
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
              title: Text('Setting'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/setting');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/back1.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )),
              Expanded(
                flex: 1,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          _showPlayerCountDialog(context);
                        },
                        child: Container(
                          width: 135,
                          height: 135,
                          child: Center(
                            child: Text(
                              'QUICK' + '\n' + 'START',
                              style:
                                  TextStyle(fontSize: 32, color: Colors.white),
                            ),
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PlayerSelectionScreen()),
                          );
                        },
                        child: Container(
                          width: 135,
                          height: 135,
                          child: Center(
                            child: Text(
                              'NEW' + '\n' + 'MATCH',
                              style:
                                  TextStyle(fontSize: 32, color: Colors.white),
                            ),
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Status: $_status',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _retryConnection();
                        },
                        child: Text('Reconnect'),
                        style: ElevatedButton.styleFrom(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () {
                _showJoinDialog(context);
              },
              child: Text('JOIN'),
              style: ElevatedButton.styleFrom(),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    String firstName = '';
    String lastName = '';
    String username = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'First Name'),
                onChanged: (value) => firstName = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Last Name'),
                onChanged: (value) => lastName = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Username'),
                onChanged: (value) => username = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('JOIN'),
              onPressed: () async {
                await _webSocketService.register(firstName, lastName, username);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPlayerCountDialog(BuildContext context) async {
    final int? count = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final playerCount = index + 2;
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop(playerCount);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 190,
                    height: 190,
                    child: Center(
                      child: Text(
                        '$playerCount Players',
                        style: TextStyle(fontSize: 35, color: Colors.white),
                      ),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: Color.fromRGBO(46, 44, 53, 1),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );

    if (count != null) {
      handicabScores = List.filled(count, 10);
      _showHandicabDialog(context, count);
    }
  }

  Future<void> _showHandicabDialog(
      BuildContext context, int playerCount) async {
    List<int?> handicapScores = List.filled(playerCount, null);
    List<TextEditingController> controllers = List.generate(
      playerCount,
      (index) => TextEditingController(),
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('HANDICAP', style: TextStyle(fontSize: 28)),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Center(
                  // 추가된 Center 위젯
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height *
                                0.2), // 상단 여백 추가
                        ...List.generate(playerCount, (index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: Text('PLAYER ${index + 1}',
                                      style: TextStyle(fontSize: 22)),
                                ),
                                SizedBox(width: 30),
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: controllers[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 20),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(16.0),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        handicapScores[index] =
                                            int.tryParse(value);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => _navigateToQuickStart(
                                  context, playerCount, handicapScores, true),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                child: Text('START',
                                    style: TextStyle(fontSize: 24)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                child: Text('CANCEL',
                                    style: TextStyle(fontSize: 24)),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height *
                                0.2), // 하단 여백 추가
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToQuickStart(BuildContext context, int playerCount,
      List<int?> handicapScores, bool isHandicap) {
    bool allHandicapsEntered = handicapScores.every((score) => score != null);
    List<int> finalHandicapScores =
        handicapScores.map((score) => score ?? 0).toList();

    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickStartScreen(
          playerCount: playerCount,
          handicabScores: finalHandicapScores,
          isHandicap: isHandicap && allHandicapsEntered,
          webSocketService: _webSocketService,
        ),
      ),
    );
  }
}
