// video_manager.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';

class VideoManager {
  late final Player player;
  late final VideoController controller;
  late FlutterFFmpeg _ffmpeg;
  late String documentDirectory;
  late String outputPath;
  bool _isLoading = true;

  VideoManager() {
    player = Player();
    controller = VideoController(player);
    _ffmpeg = FlutterFFmpeg();
  }

  Future<void> initialize(String inputPath) async {
    await _getDirectory();
    await _deleteFilesInDirectory(outputPath);
    _startConversion(inputPath);
    await _waitForSegment();
    await _initializeController();
    _isLoading = false;
  }

  Future<void> _getDirectory() async {
    documentDirectory = await _getDocumentDirectory();
    outputPath = '$documentDirectory/ffmpeg_output';
  }

  Future<String> _getDocumentDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _deleteFilesInDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        print('Files in $directoryPath deleted successfully.');
      } else {
        print('Directory $directoryPath does not exist.');
      }
    } catch (e) {
      print('Error deleting files: $e');
    }
  }

  void _startConversion(String inputPath) async {
    await Directory(outputPath).create(recursive: true);
    _runFFmpeg(inputPath, outputPath);
  }

  Future<int> _runFFmpeg(String inputPath, String outputPath) async {
    List<String> arguments = [
      '-i',
      inputPath,
      '-c:v',
      'libx264',
      '-an',
      '-threads',
      '2',
      '-preset',
      'ultrafast',
      '-f',
      'hls',
      '-s',
      '960x540',
      '-vf',
      'lenscorrection=cx=0.5:cy=0.5:k1=-0.165:k2=-0.0165',
      '-hls_time',
      '2',
      '-crf',
      '28',
      '-hls_playlist_type',
      'event',
      '-hls_list_size',
      '0',
      '-hls_segment_filename',
      '$outputPath/output_%03d.ts',
      '$outputPath/output.m3u8',
    ];

    return await _ffmpeg.executeWithArguments(arguments);
  }

  Future<void> _waitForSegment() async {
    while (!(await isSegmentGenerated())) {
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Future<bool> isSegmentGenerated() async {
    Directory directory = Directory(outputPath);
    if (await directory.exists()) {
      List<FileSystemEntity> files = directory.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.ts')) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _initializeController() async {
    print('Initializing Controller!!!');

    File file = File('$outputPath/output.m3u8');

    if (await file.exists()) {
      print('파일이 존재합니다.');
      try {
        await player.open(Media('file://$outputPath/output.m3u8'));
        print('플레이어 초기화 성공');
      } catch (e) {
        print('플레이어 초기화 실패: $e');
      }
    } else {
      print('파일이 존재하지 않습니다.');
    }
  }

  bool get isLoading => _isLoading;

  Future<void> seek(Duration duration) async {
    await player.seek(player.state.position + duration);
  }

  Future<void> dispose() async {
    player.dispose();
    _isLoading = true;
    await _deleteFilesInDirectory(outputPath);
    await _ffmpeg.cancel();
  }

  Future<void> reset() async {
    _isLoading = true;
    await _deleteFilesInDirectory(outputPath);
    await _ffmpeg.cancel();
  }
}
