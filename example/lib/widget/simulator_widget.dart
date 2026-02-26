import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:phasetida_flutter/phasetida_flutter.dart';
import 'package:phasetida_flutter_example/api/info_json.dart';

class SimulatorWidget extends StatefulWidget {
  final String levelData;
  final Uint8List songData;
  final Song songInfo;
  final Level levelInfo;

  const SimulatorWidget({
    super.key,
    required this.levelData,
    required this.songData,
    required this.songInfo,
    required this.levelInfo,
  });

  @override
  State<StatefulWidget> createState() => SimulatorWidgetState();
}

class SimulatorWidgetState extends State<SimulatorWidget> {
  @override
  void initState() {
    FullScreen.setFullScreen(true);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    FullScreen.setFullScreen(false);
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Center(
        child: PhigrosChartPlayerShellWidget(
          jsonData: widget.levelData,
          songName: widget.songInfo.name,
          author: widget.songInfo.composer,
          chartComposer: widget.levelInfo.charter,
          quitCallback: () {
            Navigator.pop(context);
          },
          songBuffer: widget.songData,
        ),
      ),
    );
  }
}
