library;

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:phasetida_flutter/src/rust/frb_generated.dart';

export 'simulator/shell.dart' show PhigrosChartPlayerShellWidget;
export 'simulator/simulator.dart' show PhigrosSimulatorRenderWidget;

const String phasetidaVersion = "0.2.0";

class PhasetidaFlutter {
  static Future<void> init() async {
    await RustLib.init();
    await SoLoud.instance.init();
  }

  static void dispose() => RustLib.dispose();
}
