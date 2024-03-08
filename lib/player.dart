import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const MyPlayView = 'MyPlayerView';

class MyPlayerView extends StatefulWidget {
  final String video_url;
  MyPlayerView({required this.video_url});

  @override
  State<MyPlayerView> createState() => _MyPlayerViewState();
}

class _MyPlayerViewState extends State<MyPlayerView> {
  final Map<String, dynamic> creationParams = <String, dynamic>{};
  @override
  void initState() {
    super.initState();
    creationParams["url"] = widget.video_url;
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid
        ? AndroidView(
            viewType: MyPlayView,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          )
        : UiKitView(
            viewType: MyPlayView,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
          );
  }
}
