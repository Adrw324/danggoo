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

  bool _isLoading = true;

  VideoManager() {
    player = Player();
    controller = VideoController(player);
    // _ffmpeg = FlutterFFmpeg();
  }

  Future<void> initialize(String inputPath) async {
    await _initializeController(inputPath);
    _isLoading = false;
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
    player.dispose();
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
      final targetPosition = duration - Duration(seconds: 1);

      final currentPosition = widget.controller.player.state.position;

      if (duration - currentPosition > Duration(seconds: 0)) {
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
                            icon: Icon(Icons.fullscreen,
                                color: Colors.white, size: 36), // 크기를 1.5배로 증가
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
                          bottom: 60,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.replay_5,
                                    color: Colors.white,
                                    size: 36), // 크기를 1.5배로 증가
                                onPressed: () {
                                  final newPosition =
                                      widget.controller.player.state.position -
                                          Duration(seconds: 5);
                                  widget.controller.player.seek(newPosition);
                                  _startHideTimer();
                                },
                              ),
                              SizedBox(width: 20), // 간격 추가
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
                                      size: 72, // 크기를 1.5배로 증가 (48 * 1.5 = 72)
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
                              SizedBox(width: 20), // 간격 추가
                              IconButton(
                                icon: Icon(Icons.forward_5,
                                    color: Colors.white,
                                    size: 36), // 크기를 1.5배로 증가
                                onPressed: () {
                                  final newPosition =
                                      widget.controller.player.state.position +
                                          Duration(seconds: 5);
                                  widget.controller.player.seek(newPosition);
                                  _startHideTimer();
                                },
                              ),
                              SizedBox(width: 20), // 간격 추가
                              IconButton(
                                icon: Icon(Icons.update,
                                    color: Colors.white,
                                    size: 36), // 크기를 1.5배로 증가
                                onPressed: () {
                                  _seekToLatestSegment();
                                  _startHideTimer();
                                },
                              ),
                            ],
                          ),
                        ),
                      // 슬라이더바 (변경 없음)
                      if (_showControls)
                        Positioned(
                          bottom: 10,
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
