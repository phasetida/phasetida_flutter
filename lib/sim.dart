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
    int tapSounds,
    int dragSounds,
    int holdSounds,
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

  void tryEvaluate(String script) =>
      webViewController?.evaluateJavascript(source: script);

  void loadLevel(String json) => tryEvaluate("window.simLoadLevel(`$json`);");

  void setSpeed(double speed) => tryEvaluate("window.simSetSpeed($speed)");

  void setTime(double time) => tryEvaluate("window.simSetTime($time)");

  void setShowDebug(bool show) =>
      tryEvaluate("window.simSetShowControls($show)");

  void setAutoPlay(bool auto) {
    tryEvaluate("window.simAuto=$auto;");
    tryEvaluate("window.simEnableTouch=${!auto};");
  }

  void setHighlight(bool highlight) =>
      tryEvaluate("window.simSimultaneousHighlight=$highlight;");

  void setLogging(bool logging) => tryEvaluate("window.simLog=$logging;");

  void setLoggingLatency(double latency) =>
      tryEvaluate("window.simLogLatency=$latency;");
}

class _PhigrosChartPlayerState extends State<PhigrosChartPlayerWidget> {
  late final InAppLocalhostServer _localServer;
  late final InAppWebViewController _webViewController;
  final InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: false,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllowFullscreen: true,
    useOnRenderProcessGone: false,
    automaticallyAdjustsScrollIndicatorInsets: false,
    isFraudulentWebsiteWarningEnabled: false,
    domStorageEnabled: true,
    databaseEnabled: true,
    hardwareAcceleration: true,
    useHybridComposition: true,
    useShouldOverrideUrlLoading: false,
    cacheEnabled: true,
    clearCache: false,
    supportZoom: false,
    builtInZoomControls: false,
    displayZoomControls: false,
    disableContextMenu: true,
    allowFileAccessFromFileURLs: false,
    allowUniversalAccessFromFileURLs: false,
    overScrollMode: OverScrollMode.NEVER,
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
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
    return RepaintBoundary(child: InAppWebView(
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
            widget.onTick(
              (it[0] as num).toDouble(),
              (it[1] as num).toDouble(),
              (it[2] as num).toInt(),
              (it[3] as num).toInt(),
              (it[4] as num).toDouble(),
              (it[5] as num).toDouble(),
              (it[6] as num).toInt(),
              (it[7] as num).toInt(),
              (it[8] as num).toInt(),
            );
          },
        );
      },
      onConsoleMessage: (controller, consoleMessage) {
        final message = consoleMessage.message;
        if (message.contains("loading assets")) {
          widget.onPageLoaded();
        }
        if (message.contains("waiting")) {
          widget.onAssetsLoaded();
        }
      },
    ));
  }

  @override
  void dispose() {
    super.dispose();
    _localServer.close();
    _webViewController.dispose();
  }
}
