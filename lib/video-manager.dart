import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'fullscreen.dart';
import 'dart:async';
import 'global.dart';

class VideoManager {
  late final Player player;
  late final VideoController controller;
  late String _currentPath;
  late GameData _gameData;
  Duration _delay = Duration(seconds: 3);
  bool _isInitialized = false;

  bool _isLoading = true;

  VideoManager(GameData gameData) {
    _gameData = gameData;
    _delay = Duration(seconds: _gameData.defaultDelay);
    _initializePlayer();
  }

  Future<void> initialize(String inputPath) async {
    _currentPath = inputPath;
    await _initializeController(_currentPath);
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

  Future<void> _applyInitialDelay() async {
    await Future.delayed(Duration(seconds: 1)); // 약간의 지연을 추가
    final duration = player.state.duration;
    if (duration > Duration.zero) {
      final targetPosition = duration - _delay;
      await player.seek(
          targetPosition > Duration.zero ? targetPosition : Duration.zero);
    }
  }

  Future<void> goToLatest() async {
    final duration = player.state.duration;
    if (duration > Duration.zero) {
      final targetPosition = duration - _delay;
      await player.seek(
          targetPosition > Duration.zero ? targetPosition : Duration.zero);
    }
  }

  Future<void> adjustDelay(int seconds) async {
    _delay += Duration(seconds: seconds);
    if (_delay < Duration.zero) {
      _delay = Duration.zero;
    }
    await goToLatest(); // 딜레이 조정 후 최신 위치로 이동
  }

  Future<void> play() async {
    await player.play();
    await Future.delayed(_delay);
    await player.seek(Duration.zero);
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> setDelay(Duration newDelay) async {
    _delay = newDelay;
  }

  Duration get currentDelay => _delay;

  bool get isLoading => _isLoading;

  Future<void> seek(Duration duration) async {
    await player.seek(player.state.position + duration);
  }

  Future<void> dispose() async {
    player.dispose();
  }

  void _initializePlayer() {
    player = Player();
    controller = VideoController(player);
    player.stream.buffering.listen((isBuffering) {
      if (!isBuffering && !_isInitialized) {
        _isInitialized = true;
        _applyInitialDelay();
      }
    });
  }

  Future<void> reloadVideo() async {
    _isLoading = true;
    await dispose();
    _initializePlayer();
    await initialize(_currentPath);
    _isLoading = false;
  }
}

class CustomVideoControls extends StatefulWidget {
  final VideoController controller;
  final bool isFullscreen;

  const CustomVideoControls({
    Key? key,
    required this.controller,
    this.isFullscreen = false,
  }) : super(key: key);

  @override
  _CustomVideoControlsState createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _showControls = true;
  Timer? _hideTimer;
  double _localSliderValue = 0.0;
  bool _isDragging = false;
  bool _isSeekInProgress = false;

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

  Future<void> _seekToLatestSegment() async {
    final duration = widget.controller.player.state.duration;
    if (duration > Duration.zero) {
      final targetPosition = duration - Duration(seconds: 2);
      await _performSeek(targetPosition);
    }
  }

  double _calculateSliderValue(Duration position, Duration duration) {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  Duration _calculatePositionFromSliderValue(double value, Duration duration) {
    return Duration(milliseconds: (value * duration.inMilliseconds).round());
  }

  Future<void> _performSeek(Duration newPosition) async {
    if (_isSeekInProgress) return;

    setState(() {
      _isSeekInProgress = true;
    });

    try {
      await widget.controller.player.seek(newPosition);
      // 세그먼트 로딩을 기다리는 로직
      await _waitForSegmentLoad();
    } finally {
      if (mounted) {
        setState(() {
          _isSeekInProgress = false;
        });
      }
    }
  }

  Future<void> _waitForSegmentLoad() async {
    // 여기에 세그먼트 로딩을 기다리는 로직을 구현합니다.
    // 예를 들어, 일정 시간 동안 대기하거나 특정 이벤트를 기다릴 수 있습니다.
    await Future.delayed(Duration(milliseconds: 500)); // 예시: 500ms 대기
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
                  _localSliderValue = _calculateSliderValue(position, duration);
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
                                color: Colors.white, size: 50),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullscreenVideoPage(
                                    controller: widget.controller,
                                  ),
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
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.replay_5,
                                      color: Colors.white, size: 50),
                                  onPressed: () {
                                    final newPosition = widget
                                            .controller.player.state.position -
                                        Duration(seconds: 5);
                                    _performSeek(newPosition);
                                    _startHideTimer();
                                  },
                                ),
                                SizedBox(width: 20),
                                StreamBuilder<bool>(
                                  stream:
                                      widget.controller.player.stream.playing,
                                  initialData:
                                      widget.controller.player.state.playing,
                                  builder: (context, snapshot) {
                                    final playing = snapshot.data ?? false;
                                    return IconButton(
                                      icon: Icon(
                                        playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 100,
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
                                SizedBox(width: 20),
                                IconButton(
                                  icon: Icon(Icons.forward_5,
                                      color: Colors.white, size: 50),
                                  onPressed: () {
                                    final newPosition = widget
                                            .controller.player.state.position +
                                        Duration(seconds: 5);
                                    _performSeek(newPosition);
                                    _startHideTimer();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      // 'Go to Latest' 버튼
                      if (_showControls)
                        Positioned(
                          bottom: 60,
                          right: 16,
                          child: IconButton(
                            icon: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Go to",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    height: 1.2,
                                  ),
                                ),
                                Text(
                                  "Latest",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () {
                              _seekToLatestSegment();
                              _startHideTimer();
                            },
                          ),
                        ),
                      // 슬라이더바
                      if (_showControls)
                        Positioned(
                          bottom: 10,
                          left: 16,
                          right: 16,
                          child: Column(
                            children: [
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
                                  onChangeEnd: (value) async {
                                    setState(() {
                                      _isDragging = false;
                                    });
                                    final newPosition =
                                        _calculatePositionFromSliderValue(
                                            value, duration);
                                    await _performSeek(newPosition);
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
                                          ? _calculatePositionFromSliderValue(
                                              _localSliderValue, duration)
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
