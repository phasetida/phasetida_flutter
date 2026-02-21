library;

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:phasetida_flutter/src/rust/frb_generated.dart';

export 'shell/shell.dart' show PhigrosChartPlayerShellWidget;
export 'simulator/simulator.dart' show PhigrosSimulatorRenderWidget;

const String phasetidaFlutterVersion = "0.3.0";
const String phasetidaCoreVersion = "0.1.14";

class PhasetidaFlutter {
  static Future<void> init() async {
    await RustLib.init();
    await SoLoud.instance.init();
  }

  static void dispose() => RustLib.dispose();
}
