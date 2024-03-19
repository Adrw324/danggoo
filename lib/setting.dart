import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>(); // GameData 인스턴스 얻기

    return Scaffold(
      appBar: AppBar(
        title: Text('Setting'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      int newValue = gameData.tabletNumber; // 초기 값 설정
                      return AlertDialog(
                        title: Text('Select New Tablet Number'),
                        content: DropdownButton<int>(
                          value: newValue,
                          onChanged: (int? value) {
                            if (value != null) {
                              newValue = value;
                            }
                          },
                          items: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
                              .map<DropdownMenuItem<int>>((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('Tablet $value'),
                            );
                          }).toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              gameData.updateTabletNumber(newValue);
                              // 변경된 데이터를 SharedPreferences에 저장
                              await gameData.saveGameData();
                              Navigator.pop(context);
                            },
                            child: Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Change Tablet Number'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      double newValue = gameData.feePerMinute; // 초기 값 설정
                      return AlertDialog(
                        title: Text('Enter New Fee'),
                        content: TextFormField(
                          initialValue: newValue.toString(),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            newValue = double.tryParse(value) ?? 0.0;
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              gameData.updateFeePerMinute(newValue);
                              // 변경된 데이터를 SharedPreferences에 저장
                              await gameData.saveGameData();
                              Navigator.pop(context);
                            },
                            child: Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Change Fee'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      String newValue = gameData.manager_uri; // 초기 값 설정
                      return AlertDialog(
                        title: Text('Enter New Manager URI'),
                        content: TextFormField(
                          initialValue: newValue,
                          onChanged: (value) {
                            newValue = value;
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              gameData.updateManagerUri(newValue);
                              // 변경된 데이터를 SharedPreferences에 저장
                              await gameData.saveGameData();
                              Navigator.pop(context);
                            },
                            child: Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Change Manager URI'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      String newValue = gameData.camera_uri; // 초기 값 설정
                      return AlertDialog(
                        title: Text('Enter New Camera URI'),
                        content: TextFormField(
                          initialValue: newValue,
                          onChanged: (value) {
                            newValue = value;
                          },
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              gameData.updateCameraUri(newValue);
                              // 변경된 데이터를 SharedPreferences에 저장
                              await gameData.saveGameData();
                              Navigator.pop(context);
                            },
                            child: Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Change Camera URI'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Exit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
