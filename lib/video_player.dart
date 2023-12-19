import 'package:flutter/material.dart';
import 'package:flutter_playout/player_observer.dart';
import 'package:flutter_playout/player_state.dart';
import 'package:flutter_playout/video.dart';

class VideoPlayout extends StatefulWidget {
  final PlayerState desiredState;
  final bool showPlayerControls;
  final String url;

  double duration = 0;

  VideoPlayout(
      {required key,
      required this.desiredState,
      required this.showPlayerControls,
      required this.url,
      this.duration = 0})
      : super(key: key);

  @override
  _VideoPlayoutState createState() => _VideoPlayoutState();
}

class _VideoPlayoutState extends State<VideoPlayout> with PlayerObserver {
  String _url = 'null';

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          /* player */
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Video(
              autoPlay: true,
              showControls: widget.showPlayerControls,
              isLiveStream: false,
              position: 0,
              url: widget.url,
              onViewCreated: _onViewCreated,
              desiredState: widget.desiredState,
              loop: false,
            ),
          ),
        ],
      ),
    );
  }

  void _onViewCreated(int viewId) {
    listenForVideoPlayerEvents(viewId);
  }

  @override
  void onPlay() {
    // TODO: implement onPlay
    super.onPlay();
  }

  @override
  void onPause() {
    // TODO: implement onPause
    super.onPause();
  }

  @override
  void onComplete() {
    // TODO: implement onComplete
    super.onComplete();
  }

  @override
  void onTime(int? position) {
    // TODO: implement onTime
    super.onTime(position);
  }

  @override
  void onSeek(int? position, double offset) {
    // TODO: implement onSeek
    super.onSeek(position, offset);
  }

  @override
  void onDuration(int? duration) {
    // TODO: implement onDuration
    duration = duration;
  }

  @override
  void onError(String? error) {
    // TODO: implement onError
    super.onError(error);
  }
}
