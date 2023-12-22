package com.example.danggoo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {

        super.configureFlutterEngine(flutterEngine)
        tv.mta.flutter_playout.video.PlayerViewFactory.registerWith(
                flutterEngine.platformViewsController.registry,
                flutterEngine.dartExecutor.binaryMessenger,
                this)

        tv.mta.flutter_playout.audio.AudioPlayer.registerWith(
                flutterEngine.dartExecutor.binaryMessenger,
                this, context)
    }
}