import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../global.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _statusController = StreamController<String>.broadcast();
  final _messageController = StreamController<String>.broadcast();
  final String _serverUrl;
  final GameData _gameData;
  bool _isConnecting = false;
  bool _isClosed = false;

  WebSocketService(this._serverUrl, this._gameData);

  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get messageStream => _messageController.stream;

  Future<void> connect() async {
    if (_isConnecting || _isClosed) return;
    _isConnecting = true;

    try {
      await _closeChannel();

      final tableId = _gameData.tabletNumber;
      final url = 'ws://$_serverUrl/ws?tableId=$tableId';
      print("Attempting to connect to: $url");

      _channel = IOWebSocketChannel.connect(Uri.parse(url));
      _updateStatus("Connecting...");

      _channel!.stream.listen(
        (message) {
          print("Received message: $message");
          _messageController.add(message.toString());
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _updateStatus('Connection Error: $error');
          _reconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _updateStatus('Connection Closed');
          _reconnect();
        },
      );

      await _channel!.ready;
      _updateStatus("Connected");
      _sendConnectedStatus(true);
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _updateStatus('Connection Failed: $e');
      _reconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void _handleMessage(dynamic message) {
    print("Raw message received: $message");
    try {
      final jsonMessage = jsonDecode(message);
      print("Parsed message: $jsonMessage");
      switch (jsonMessage['type']) {
        case 'ForceStartGame':
          int tableId = jsonMessage['tableId'];
          print("Received ForceStartGame for table $tableId");
          if (tableId == _gameData.tabletNumber) {
            _messageController.add('ForceStartGame');
          }
          break;
        case 'ForceEndGame':
          int tableId = jsonMessage['tableId'];
          print("Received ForceEndGame for table $tableId");
          if (tableId == _gameData.tabletNumber) {
            _messageController.add('ForceEndGame');
          }
          break;
        case 'GameStarted':
          int tableId = jsonMessage['tableId'];
          print("Received GameStarted for table $tableId");
          if (tableId == _gameData.tabletNumber) {
            _messageController.add('GameStarted');
          }
          break;
        case 'GameEnded':
          int tableId = jsonMessage['tableId'];
          print("Received GameEnded for table $tableId");
          if (tableId == _gameData.tabletNumber) {
            _messageController.add('GameEnded');
          }
          break;
        case 'connectionStatus':
          bool isConnected = jsonMessage['isConnected'];
          print("Received connectionStatus: $isConnected");
          _updateStatus(isConnected ? 'Connected' : 'Disconnected');
          break;
        default:
          print("Unhandled message type: ${jsonMessage['type']}");
      }
    } catch (e) {
      print("Error parsing message: $e");
    }
  }

  void _reconnect() {
    if (!_isConnecting && !_isClosed) {
      print('Attempting to reconnect in 5 seconds...');
      Future.delayed(Duration(seconds: 5), () {
        connect();
      });
    }
  }

  Future<void> _closeChannel() async {
    await _channel?.sink.close();
    _channel = null;
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && !_isClosed) {
      final jsonMessage = jsonEncode(message);
      print("Sending message: $jsonMessage");
      _channel!.sink.add(jsonMessage);
    } else {
      print("Cannot send message: channel is null or service is closed");
    }
  }

  void _sendConnectedStatus(bool isConnected) {
    sendMessage({
      'type': 'updateTableStatus',
      'tableId': _gameData.tabletNumber,
      'isActive': isConnected
    });
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    print("Closing WebSocket connection");
    await _closeChannel();
    await _statusController.close();
    await _messageController.close();
  }

  void _updateStatus(String status) {
    if (!_isClosed) {
      print("WebSocket status updated: $status");
      _statusController.add(status);
    }
  }

  void retryConnection() async {
    if (_isClosed) {
      print("Cannot retry connection: WebSocketService is closed");
      return;
    }
    await _closeChannel();
    await connect();
  }

  Future<void> register(
      String firstName, String lastName, String username) async {
    sendMessage({
      'type': 'register',
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
    });
  }

  Future<void> searchPlayers(String query) async {
    sendMessage({
      'type': 'searchPlayers',
      'query': query,
    });
  }
}
