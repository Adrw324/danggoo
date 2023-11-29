import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class GameData extends ChangeNotifier {
  int tabletNumber = 1;
  double feePerMinute = 1;
  String manager_uri = 'localhost:5157';
  String camera_uri = '';

  void updateTabletNumber(int newTabletNumber) {
    tabletNumber = newTabletNumber;
    notifyListeners();
  }

  void updateFeePerMinute(double newFeePerMin) {
    feePerMinute = newFeePerMin;
    notifyListeners();
  }

  void updateManagerUri(String newManagerUri) {
    manager_uri = newManagerUri;
    notifyListeners();
  }

  void updateCameraUri(String newCameraUri) {
    camera_uri = newCameraUri;
    notifyListeners();
  }
}

class GameDataSender {
  Future<void> sendGameData(Game game, GameData gameData) async {
    String serverUrl = gameData.manager_uri;
    final apiUrl = Uri.http('$serverUrl', '/Games/Receive');
    final headers = {
      'Content-Type': 'application/json',
      "Access-Control_Allow_Origin": "*",
      'Accept': '*/*'
    };
    final DataToSend = game.toJson();

    try {
      final response = await http.post(
        apiUrl,
        headers: headers,
        body: jsonEncode(DataToSend),
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

class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(DiagonalClipper oldClipper) => false;
}
