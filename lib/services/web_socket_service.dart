import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final _statusController = StreamController<String>.broadcast();
  int _tableId;
  final String _serverUrl;

  WebSocketService(this._tableId, this._serverUrl);

  Stream<String> get statusStream => _statusController.stream;

  void connect() {
    try {
      print("Attempting to connect to: ws://$_serverUrl/ws?tableId=$_tableId");
      _channel =
          IOWebSocketChannel.connect('ws://$_serverUrl/ws?tableId=$_tableId');
      _updateStatus("Connecting...");

      _channel!.stream.listen(
        (message) {
          print("WebSocket connected successfully. Received message: $message");
          _updateStatus("Connected");
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
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _updateStatus('Connection Failed: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    print('Attempting to reconnect in 5 seconds...');
    Future.delayed(Duration(seconds: 5), () {
      connect();
    });
  }

  void sendMessage(String message) {
    if (_channel != null) {
      print("Sending message: $message");
      _channel!.sink.add(message);
    } else {
      print("Cannot send message: channel is null");
    }
  }

  void close() {
    print("Closing WebSocket connection");
    _channel?.sink.close();
    _updateStatus("Disconnected");
    _statusController.close();
  }

  void _updateStatus(String status) {
    print("WebSocket status updated: $status");
    _statusController.add(status);
  }
}
