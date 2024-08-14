// video_manager.dart
import 'dart:io';
import 'package:danggoo/global.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'fullscreen.dart';
import 'dart:async';

class VideoManager {
  late final Player player;
  late final VideoController controller;
  // late FlutterFFmpeg _ffmpeg;
  // late String documentDirectory;
  // late String outputPath;
  bool _isLoading = true;

  VideoManager() {
    player = Player();
    controller = VideoController(player);
    // _ffmpeg = FlutterFFmpeg();
  }

  Future<void> initialize(String inputPath) async {
    // await _getDirectory();
    // await _deleteFilesInDirectory(outputPath);
    // _startConversion(inputPath);
    // await _waitForSegment();
    await _initializeController(inputPath);
    _isLoading = false;
  }

  Future<void> _getDirectory() async {
    // documentDirectory = await _getDocumentDirectory();
    // outputPath = '$documentDirectory/ffmpeg_output';
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
    // await Directory(outputPath).create(recursive: true);
    // _runFFmpeg(inputPath, outputPath);
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
      'veryfast',
      '-f',
      'hls',
      '-s',
      '960x540',
      '-vf',
      'lenscorrection=cx=0.5:cy=0.5:k1=-0.185:k2=-0.011',
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

    return 1;
  }

  Future<void> _waitForSegment() async {
    while (!(await isSegmentGenerated())) {
      await Future.delayed(Duration(seconds: 1));
    }
  }

  Future<bool> isSegmentGenerated() async {
    // Directory directory = Directory(outputPath);
    // if (await directory.exists()) {
    //   List<FileSystemEntity> files = directory.listSync();
    //   for (var file in files) {
    //     if (file is File && file.path.endsWith('.ts')) {
    //       return true;
    //     }
    //   }
    // }
    return false;
  }

  Future<void> _initializeController(String inputPath) async {
    print('Initializing Controller!!!');

    try {
      await player.open(Media(inputPath));
      await player.stream.duration.first;
      print('플레이어 초기화 성공');
    } catch (e) {
      print('플레이어 초기화 실패: $e');
    }
  }

  bool get isLoading => _isLoading;

  Future<void> seek(Duration duration) async {
    await player.seek(player.state.position + duration);
  }

  Future<void> dispose() async {
    // player.dispose();
    // _isLoading = true;
    // await _deleteFilesInDirectory(outputPath);
    // await _ffmpeg.cancel();
  }

  Future<void> reset() async {
    // _isLoading = true;
    // await _deleteFilesInDirectory(outputPath);
    // await _ffmpeg.cancel();
  }
}

class CustomVideoControls extends StatefulWidget {
  final VideoController controller;
  final bool isFullscreen;

  const CustomVideoControls(
      {Key? key, required this.controller, this.isFullscreen = false})
      : super(key: key);

  @override
  _CustomVideoControlsState createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _showControls = true;
  Timer? _hideTimer;
  double _localSliderValue = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _handleTap() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideTimer();
      } else {
        _hideTimer?.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _seekToLatestSegment() {
    final duration = widget.controller.player.state.duration;
    if (duration > Duration.zero) {
      // 전체 길이에서 5초를 뺀 지점으로 이동
      // 5초는 버퍼 시간을 고려한 값으로, 필요에 따라 조정 가능
      final targetPosition = duration - Duration(seconds: 2);

      // 현재 위치를 확인
      final currentPosition = widget.controller.player.state.position;

      // 현재 위치가 목표 위치보다 10초 이상 뒤쳐져 있을 때만 이동
      if (duration - currentPosition > Duration(seconds: 3)) {
        widget.controller.player.seek(targetPosition);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onDoubleTap: () {
          if (widget.controller.player.state.playing) {
            widget.controller.player.pause();
          } else {
            widget.controller.player.play();
          }
          _startHideTimer();
        },
        child: StreamBuilder<Duration>(
          stream: widget.controller.player.stream.position,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration>(
              stream: widget.controller.player.stream.duration,
              builder: (context, durationSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = durationSnapshot.data ?? Duration.zero;

                if (!_isDragging) {
                  _localSliderValue = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;
                }

                return AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Stack(
                    children: [
                      // 풀스크린 버튼
                      if (_showControls && !widget.isFullscreen)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            icon: Icon(Icons.fullscreen, color: Colors.white),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullscreenVideoPage(
                                      controller: widget.controller),
                                ),
                              );
                              if (mounted) {
                                setState(() {
                                  _showControls = true;
                                });
                                _startHideTimer();
                              }
                            },
                          ),
                        ),
                      // 컨트롤 버튼들
                      if (_showControls)
                        Positioned(
                          bottom: 60, // 아래쪽 패딩 조정
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.replay_5, color: Colors.white),
                                onPressed: () {
                                  final newPosition =
                                      widget.controller.player.state.position -
                                          Duration(seconds: 5);
                                  widget.controller.player.seek(newPosition);
                                  _startHideTimer();
                                },
                              ),
                              StreamBuilder<bool>(
                                stream: widget.controller.player.stream.playing,
                                initialData:
                                    widget.controller.player.state.playing,
                                builder: (context, snapshot) {
                                  final playing = snapshot.data ?? false;
                                  return IconButton(
                                    icon: Icon(
                                      playing ? Icons.pause : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                    onPressed: () {
                                      if (playing) {
                                        widget.controller.player.pause();
                                      } else {
                                        widget.controller.player.play();
                                      }
                                      _startHideTimer();
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    Icon(Icons.forward_5, color: Colors.white),
                                onPressed: () {
                                  final newPosition =
                                      widget.controller.player.state.position +
                                          Duration(seconds: 5);
                                  widget.controller.player.seek(newPosition);
                                  _startHideTimer();
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.update, color: Colors.white),
                                onPressed: () {
                                  _seekToLatestSegment();
                                  _startHideTimer();
                                },
                              ),
                            ],
                          ),
                        ),
                      // 슬라이더바
                      if (_showControls)
                        Positioned(
                          bottom: 10, // 아래쪽 패딩 조정
                          left: 16,
                          right: 16,
                          child: Column(
                            children: [
                              if (duration != Duration.zero)
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                    overlayShape: RoundSliderOverlayShape(
                                        overlayRadius: 12),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: _localSliderValue,
                                    onChanged: (value) {
                                      setState(() {
                                        _localSliderValue = value;
                                        _isDragging = true;
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      setState(() {
                                        _isDragging = false;
                                      });
                                      final newPosition = Duration(
                                          milliseconds:
                                              (value * duration.inMilliseconds)
                                                  .round());
                                      widget.controller.player
                                          .seek(newPosition);
                                    },
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_isDragging
                                          ? Duration(
                                              milliseconds: (_localSliderValue *
                                                      duration.inMilliseconds)
                                                  .round())
                                          : position),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
