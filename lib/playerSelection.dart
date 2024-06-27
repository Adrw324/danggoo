import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/web_socket_service.dart';
import 'match.dart';
import 'global.dart';

class Player {
  final int id;
  final String firstName;
  final String lastName;
  final String username;

  Player(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.username});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['Id'] as int,
      firstName: json['FirstName'] as String,
      lastName: json['LastName'] as String,
      username: json['Username'] as String,
    );
  }
}

class PlayerSelectionScreen extends StatefulWidget {
  @override
  _PlayerSelectionScreenState createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  List<Player> players = [];
  Player? player1;
  Player? player2;
  late WebSocketService _webSocketService;
  int? selectedSlot; // 1 for player1, 2 for player2
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
    _webSocketService.messageStream.listen(_handleIncomingMessage);
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
            players = playersData.map((p) => Player.fromJson(p)).toList();
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

  Future<void> _fetchPlayers() async {
    // TODO: Implement player fetching from the server
    // For now, we'll use dummy data
    setState(() {
      players = List.generate(
        10,
        (index) => Player(
          id: index + 1,
          firstName: "Player ${index + 1}",
          lastName: "Player ${index + 1}",
          username: "player${index + 1}",
        ),
      );
    });
  }

  void _searchPlayers(String query) {
    _webSocketService.searchPlayers(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E2761), // Dark blue background
      appBar: AppBar(
        title: Text('Select Players'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          _buildPlayerSlot(1),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: _buildPlayerList(),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
          _buildPlayerSlot(2),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search players...',
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          _searchPlayers(value);
        },
      ),
    );
  }

  Widget _buildPlayerList() {
    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.grey[850],
          child: ListTile(
            leading: CircleAvatar(
              child: Text(players[index].firstName[0]),
            ),
            title: Text(
                '${players[index].firstName} ${players[index].lastName}',
                style: TextStyle(color: Colors.white)),
            subtitle: Text(players[index].username,
                style: TextStyle(color: Colors.grey)),
            onTap: () {
              if (selectedSlot == 1) {
                setState(() => player1 = players[index]);
              } else if (selectedSlot == 2) {
                setState(() => player2 = players[index]);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildPlayerSlot(int slotNumber) {
    Player? selectedPlayer = slotNumber == 1 ? player1 : player2;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedSlot = slotNumber),
        child: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                selectedSlot == slotNumber ? Colors.orange : Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 50, color: Colors.white),
              SizedBox(height: 8),
              Text(
                selectedPlayer?.firstName ?? 'Player $slotNumber',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        ),
        ElevatedButton(
          child: Text('Submit'),
          onPressed: player1 != null && player2 != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MatchScreen(
                        player1Name: player1!.username,
                        player2Name: player2!.username,
                        webSocketService: _webSocketService,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
      ],
    );
  }
}
