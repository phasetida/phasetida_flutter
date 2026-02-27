import 'package:flutter/material.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:phasetida_flutter/phasetida_flutter.dart';
import 'package:phasetida_flutter_example/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhasetidaFlutter.init();
  await FullScreen.ensureInitialized();
  runApp(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: const App()
    )
  );
  PhasetidaFlutter.dispose();
}
