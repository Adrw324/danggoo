package com.example.danggoo;

import io.flutter.embedding.android.FlutterActivity;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class BaseActivity extends FlutterActivity {
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        tv.mta.flutter_playout.video.PlayerViewFactory.registerWith(
                flutterEngine.getPlatformViewsController().getRegistry(),
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                this);
        tv.mta.flutter_playout.audio.AudioPlayer.registerWith(
                            flutterEngine.getDartExecutor().getBinaryMessenger(),
                            this,
                            this.getContext());
    }
}
