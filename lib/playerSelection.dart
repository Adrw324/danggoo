import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/web_socket_service.dart';
import 'match.dart';
import 'global.dart';

class GamePlayer {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  double average;
  int totalPlay;
  int totalScore;
  int handicap;

  GamePlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.average,
    required this.totalPlay,
    required this.totalScore,
    this.handicap = 10,
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      id: json['Id'] as int,
      firstName: json['FirstName'] as String,
      lastName: json['LastName'] as String,
      username: json['Username'] as String,
      average: (json['Average'] as num).toDouble(),
      totalPlay: json['TotalPlay'] as int,
      totalScore: json['TotalScore'] as int,
    );
  }
}

class PlayerSelectionScreen extends StatefulWidget {
  @override
  _PlayerSelectionScreenState createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  List<GamePlayer> players = [];
  GamePlayer? player1;
  GamePlayer? player2;
  late WebSocketService _webSocketService;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final gameData = Provider.of<GameData>(context, listen: false);
    _webSocketService = WebSocketService(gameData.manager_uri, gameData);
    _webSocketService.messageStream.listen(_handleIncomingMessage);
    _webSocketService.connect().then((_) {
      _searchPlayers('');
    });
  }

  void _handleIncomingMessage(String message) {
    print("Received message: $message");
    try {
      final jsonMessage = jsonDecode(message);
      if (jsonMessage['type'] == 'playerList') {
        print("Received player list: ${jsonMessage['players']}");
        var playersData = jsonMessage['players'];
        if (playersData is List) {
          setState(() {
            players = playersData.map((p) => GamePlayer.fromJson(p)).toList();
          });
        } else {
          print("Error: 'players' is not a List");
        }
      }
    } catch (e, stackTrace) {
      print("Error parsing message: $e");
      print("Stack trace: $stackTrace");
    }
    print("Parsed players: $players");
  }

  void _searchPlayers(String query) {
    _webSocketService.searchPlayers(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text('Select Players'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildPlayerSlot(1, player1)),
                Expanded(
                  flex: 2,
                  child: _buildPlayerList(),
                ),
                Expanded(child: _buildPlayerSlot(2, player2)),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.black), // 입력 텍스트 색상
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: Colors.grey[600]), // 힌트 텍스트 색상
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]), // 검색 아이콘 추가
        ),
        onChanged: (value) {
          _searchPlayers(value);
        },
      ),
    );
  }

  Widget _buildPlayerList() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(), // 여기를 변경했습니다
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          final isSelected = player == player1 || player == player2;
          return Card(
            color: isSelected ? Colors.orange : Colors.grey[850],
            child: ListTile(
              leading: CircleAvatar(
                child: Text(player.firstName[0]),
              ),
              title: Text(
                '${player.firstName} ${player.lastName}',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${player.username} (Avg: ${player.average.toStringAsFixed(2)})',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () => _selectPlayer(player),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerSlot(int slotNumber, GamePlayer? selectedPlayer) {
    String slotText;
    if (selectedPlayer == null) {
      if (slotNumber == 1 && player1 == null) {
        slotText = 'Choose Player 1';
      } else if (slotNumber == 2 && player1 != null) {
        slotText = 'Choose Player 2';
      } else {
        slotText = '';
      }
    } else {
      slotText = selectedPlayer.firstName;
    }

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: selectedPlayer != null ? Colors.cyan : Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 50, color: Colors.white),
          SizedBox(height: 8),
          Text(
            slotText,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          if (selectedPlayer != null) ...[
            Text(
              selectedPlayer.username,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              'Avg: ${selectedPlayer.average.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              child: Text('Set Handicap: ${selectedPlayer.handicap}'),
              onPressed: () => _showHandicapDialog(selectedPlayer),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }

  void _showHandicapDialog(GamePlayer player) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String handicapString = player.handicap.toString();
        return AlertDialog(
          content: TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: 'Handicap'),
            controller: TextEditingController(text: handicapString),
            onChanged: (value) {
              handicapString = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                setState(() {
                  player.handicap = int.tryParse(handicapString) ?? 10;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: ElevatedButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: ElevatedButton(
              child: Text(
                'Start Match',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onPressed: player1 != null && player2 != null
                  ? () => _startMatch(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlayer(GamePlayer player) {
    setState(() {
      if (player == player1) {
        player1 = null;
      } else if (player == player2) {
        player2 = null;
      } else if (player1 == null) {
        player1 = player;
      } else if (player2 == null) {
        player2 = player;
      }
    });
  }

  void _startMatch(BuildContext context) {
    if (player1 != null && player2 != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MatchScreen(
            player1: player1!,
            player2: player2!,
            webSocketService: _webSocketService,
          ),
        ),
      );
    }
  }
}
