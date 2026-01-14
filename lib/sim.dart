import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PhigrosChartPlayerWidget extends StatefulWidget {
  final int port;
  final PhigrosChartPlayerController controller;
  final Function() onPageLoaded;
  final Function() onAssetsLoaded;
  final Function(
    double currentTime,
    double totalTime,
    int combo,
    int maxConbo,
    double score,
    double accurate,
  )
  onTick;

  const PhigrosChartPlayerWidget({
    super.key,
    required this.controller,
    required this.port,
    required this.onPageLoaded,
    required this.onAssetsLoaded,
    required this.onTick,
  });

  @override
  State<StatefulWidget> createState() => _PhigrosChartPlayerState();
}

class PhigrosChartPlayerController {
  InAppWebViewController? webViewController;

  void loadLevel(String json) {
    webViewController?.evaluateJavascript(
      source: "window.simLoadLevel(`$json`);",
    );
  }

  void setSpeed(double speed) {
    webViewController?.evaluateJavascript(source: "window.simSetSpeed($speed)");
  }

  void setTime(double time) {
    webViewController?.evaluateJavascript(source: "window.simSetTime($time)");
  }

  void setShowDebug(bool show) {
    webViewController?.evaluateJavascript(
      source: "window.simSetShowControls($show)",
    );
  }

  void setAutoPlay(bool auto) {
    webViewController?.evaluateJavascript(source: "window.simAuto=$auto;");
    webViewController?.evaluateJavascript(
      source: "window.simEnableTouch=${!auto};",
    );
  }

  void setHighlight(bool highlight) {
    webViewController?.evaluateJavascript(
      source: "window.simSimultaneousHighlight=$highlight;",
    );
  }

  void setLogging(bool logging) {
    webViewController?.evaluateJavascript(source: "window.simLog=$logging;");
  }

  void setLoggingLatency(double latency) {
    webViewController?.evaluateJavascript(
      source: "window.simLogLatency=$latency;",
    );
  }
}

class _PhigrosChartPlayerState extends State<PhigrosChartPlayerWidget> {
  late final InAppLocalhostServer _localServer;
  late final InAppWebViewController _webViewController;
  final InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: kDebugMode,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllowFullscreen: true,
  );

  @override
  void initState() {
    _localServer = InAppLocalhostServer(
      port: widget.port,
      documentRoot: "packages/phasetida_flutter/assets/",
    );
    _localServer.start();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(
          "http://localhost:${widget.port}/phasetida-node-demo/index.html",
        ),
      ),
      initialSettings: settings,
      onWebViewCreated: (controller) {
        _webViewController = controller;
        widget.controller.webViewController = controller;
        controller.addJavaScriptHandler(
          handlerName: "flutterTick",
          callback: (it) {
            final ticks = (it[0] as String).substring(1).split(",");
            widget.onTick(
              double.tryParse(ticks[0]) ?? 0.0,
              double.tryParse(ticks[1]) ?? 0.0,
              int.tryParse(ticks[2]) ?? 0,
              int.tryParse(ticks[3]) ?? 0,
              double.tryParse(ticks[4]) ?? 0.0,
              double.tryParse(ticks[5]) ?? 0.0,
            );
          },
        );
      },
      onConsoleMessage: (controller, consoleMessage) {
        final message = consoleMessage.message;
        if (kDebugMode) {
          print(consoleMessage);
        }
        if (message.contains("loading assets")) {
          widget.onPageLoaded();
        }
        if (message.contains("waiting")) {
          widget.onAssetsLoaded();
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _localServer.close();
    _webViewController.dispose();
  }
}
