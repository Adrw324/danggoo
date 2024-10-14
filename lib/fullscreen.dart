import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'video-manager.dart';

class FullscreenVideoPage extends StatefulWidget {
  final VideoController controller;
  final Duration defaultDelay;

  FullscreenVideoPage({required this.controller, required this.defaultDelay});

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
            maxScale: 4.0,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9, // 비디오의 실제 비율에 맞게 조정하세요
                child: Video(
                  controller: widget.controller,
                  controls: (state) => CustomVideoControls(
                      controller: widget.controller,
                      isFullscreen: true,
                      defaultDelay: widget.defaultDelay),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 30,
            child: IconButton(
              icon: Icon(Icons.fullscreen_exit, color: Colors.white, size: 50),
              onPressed: () {
                _transformationController.value = Matrix4.identity();
                Navigator.pop(context);
              },
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
