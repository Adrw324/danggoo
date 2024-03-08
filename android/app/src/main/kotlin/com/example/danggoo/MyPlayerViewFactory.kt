package com.example.danggoo


import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MyPlayerViewFactory(private val activity: Activity) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
    val creationParams = args as Map<String?, Any?>? 
    return MyPlayerView(context, viewId, creationParams,activity)
  }
}