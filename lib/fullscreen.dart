import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class FullscreenVideoPage extends StatefulWidget {
  final VideoController controller;

  FullscreenVideoPage({required this.controller});

  @override
  _FullscreenVideoPageState createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1.0,
            maxScale: 3.0,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9, // 비디오의 실제 비율에 맞게 조정하세요
                child: Video(
                  controller: widget.controller,
                  controls: (state) => MaterialVideoControlsTheme(
                    normal: MaterialVideoControlsThemeData(
                      volumeGesture: false,
                      brightnessGesture: false,
                      seekOnDoubleTap: true,
                      bottomButtonBar: const [
                        MaterialPositionIndicator(),
                        Spacer(),
                        // MaterialFullscreenButton() 제거됨
                      ],
                    ),
                    fullscreen: MaterialVideoControlsThemeData(
                      volumeGesture: false,
                      brightnessGesture: false,
                      seekOnDoubleTap: true,
                      bottomButtonBar: const [
                        MaterialPositionIndicator(),
                        Spacer(),
                        // MaterialFullscreenButton() 제거됨
                      ],
                    ),
                    child: MaterialVideoControls(state),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.fullscreen_exit),
              onPressed: () {
                _transformationController.value = Matrix4.identity();
                Navigator.pop(context);
              },
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}
