import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:phasetida_flutter/phasetida_flutter.dart';

late String jsonData;
late Uint8List songBuffer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhasetidaFlutter.init();
  jsonData = await rootBundle.loadString("assets/testv1.json");
  songBuffer = (await rootBundle.load("assets/song.ogg")).buffer.asUint8List();
  await FullScreen.ensureInitialized();
  FullScreen.setFullScreen(true);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
  PhasetidaFlutter.dispose();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Center(
        child: PhigrosChartPlayerShellWidget(
          jsonData: jsonData,
          songName: "RR",
          author: "TG",
          chartComposer: "X",
          songBuffer: songBuffer,
          quitCallback: () => {},
        ),
      ),
    );
  }
}
