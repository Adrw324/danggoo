import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'video-manager.dart';

class FullscreenVideoPage extends StatelessWidget {
  final VideoController controller;

  FullscreenVideoPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Video(
                  controller: controller,
                  controls: (state) => CustomVideoControls(
                    controller: controller,
                    isFullscreen: true,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 30,
              child: IconButton(
                icon: Icon(
                  Icons.fullscreen_exit,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
