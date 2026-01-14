import 'package:flutter/material.dart';
import 'package:phasetida_flutter/sim.dart';

class PhigrosChartPlayerShellWidget extends StatefulWidget {
  final String jsonData;
  final int port;
  final String songName;
  final String author;
  final String chartComposer;
  final Function() quitCallback;

  const PhigrosChartPlayerShellWidget({
    super.key,
    required this.jsonData,
    required this.port,
    required this.songName,
    required this.author,
    required this.chartComposer,
    required this.quitCallback
  });

  @override
  State<StatefulWidget> createState() => _PhigrosChartPlayerShellState();
}

class _PhigrosChartPlayerShellState
    extends State<PhigrosChartPlayerShellWidget> {
  final controller = PhigrosChartPlayerController();
  bool auto = true;
  bool highlight = true;

  double time = 0.0;
  double totalTime = 0.0;
  int combo = 0;
  int maxCombo = 0;
  double score = 0.0;
  double accurate = 0.0;

  double slideTime = 0;
  bool sliding = false;

  Speed speedSelection = Speed.x100;
  bool showSpeedSelector = true;
  bool paused = false;

  double? abStart;
  double? abEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 8,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SizedBox.expand(child: Container(color: Colors.black54)),
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1920.0 / 1080.0,
                        child: PhigrosChartPlayerWidget(
                          port: 11451,
                          controller: controller,
                          onAssetsLoaded: () async {
                            controller.loadLevel(widget.jsonData);
                            controller.setLogging(true);
                            controller.setLoggingLatency(1000.0 / 60.0);
                          },
                          onPageLoaded: () {
                            controller.setShowDebug(false);
                          },
                          onTick:
                              (
                                time,
                                totalTime,
                                combo,
                                maxCombo,
                                score,
                                accurate,
                              ) {
                                setState(() {
                                  this.time = time;
                                  this.totalTime = totalTime;
                                  this.combo = combo;
                                  this.maxCombo = maxCombo;
                                  this.score = score;
                                  this.accurate = accurate;
                                  final abStart = this.abStart;
                                  final abEnd = this.abEnd;
                                  if (abStart != null && abEnd != null) {
                                    if (time > abEnd || time < abStart) {
                                      controller.setTime(abStart);
                                    }
                                  }
                                });
                              },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(flex: 0, child: _bottomController(context)),
            ],
          ),
        ),
        Flexible(flex: 3, child: _sideMenu(context)),
      ],
    );
  }

  Widget _bottomController(BuildContext context) {
    final colorTheme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Slider(
            value: (sliding ? slideTime : time).clamp(0, totalTime),
            max: totalTime,
            onChangeStart: (v) {
              setState(() {
                sliding = true;
                slideTime = time;
              });
            },
            onChanged: (v) {
              controller.setTime(v);
              slideTime = v;
            },
            onChangeEnd: (v) {
              setState(() {
                controller.setTime(v);
                sliding = false;
                slideTime = v;
              });
            },
          ),
        ),
        Flexible(
          flex: 0,
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    paused = !paused;
                  });
                  updateSpeed();
                },
                icon: Icon(paused ? Icons.play_arrow_sharp : Icons.pause),
              ),
              IconButton(
                onPressed: () {
                  if (abEnd == null) {
                    if (abStart == null) {
                      abStart = time;
                      return;
                    }
                    abEnd = time;
                    return;
                  }
                  abEnd = null;
                  abStart = null;
                },
                icon: Icon(
                  abEnd != null && abStart != null
                      ? Icons.repeat_on
                      : Icons.repeat,
                  color: abEnd == null
                      ? abStart == null
                            ? colorTheme.colorScheme.outline
                            : colorTheme.colorScheme.onSurface
                      : colorTheme.colorScheme.primary,
                ),
              ),
              DropdownButton(
                icon: Icon(Icons.speed),
                isDense: true,
                underline: SizedBox.shrink(),
                value: speedSelection,
                items: [
                  DropdownMenuItem(value: Speed.x025, child: Text("x.25")),
                  DropdownMenuItem(value: Speed.x050, child: Text("x.50")),
                  DropdownMenuItem(value: Speed.x075, child: Text("x.75")),
                  DropdownMenuItem(value: Speed.x100, child: Text("x1.0")),
                  DropdownMenuItem(value: Speed.x125, child: Text("x1.25")),
                ],
                onChanged: (v) {
                  setState(() {
                    speedSelection = v ?? Speed.x100;
                  });
                  updateSpeed();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sideMenu(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsGeometry.all(16),
      child: SizedBox.expand(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [

              Text(widget.songName, style: theme.textTheme.titleLarge),
              Text(widget.author, style: theme.textTheme.titleMedium),
              Text(widget.chartComposer, style: theme.textTheme.titleMedium),
              SizedBox(height: 8),
              Text("Time"),
              Text(
                "${_formatTime(time.clamp(0, totalTime))}/${_formatTime(totalTime)}",
                style: theme.textTheme.titleLarge,
              ),
              Text("Score"),
              Text(score.toStringAsFixed(0), style: theme.textTheme.titleLarge),
              Text("Combo/MaxCombo"),
              Text(
                "${combo.toStringAsFixed(0)}/${maxCombo.toStringAsFixed(0)}",
                style: theme.textTheme.titleLarge,
              ),
              Text("Accuracy"),
              Text(
                "${(accurate * 100).toStringAsFixed(4)}%",
                style: theme.textTheme.titleLarge,
              ),
              Text("A-B Repeat"),
              Text(
                "${_formatTime(abStart)}/${_formatTime(abEnd)}",
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              _checkBoxTile(
                value: auto,
                text: Text("自动播放"),
                onChanged: (v) {
                  setState(() {
                    auto = v ?? false;
                  });
                  controller.setAutoPlay(auto);
                },
              ),
              if (!auto) Text("注：非自动播放为实验性功能，在部分设备上会出现触控问题"),
              _checkBoxTile(
                value: highlight,
                text: Text("多押高亮"),
                onChanged: (v) {
                  setState(() {
                    highlight = v ?? false;
                  });
                  controller.setHighlight(highlight);
                },
              ),
              OutlinedButton(onPressed: widget.quitCallback, child: Text("退出铺面预览"))
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(double? time) {
    if (time == null) return "-";
    final minute = (time / 60.0).floor().toInt();
    final second = (time - (time / 60.0).floor() * 60).toInt();
    final millisecond = ((time - minute * 60.0 - second) * 1000.0)
        .round()
        .toInt();
    return "${"$minute".padLeft(2, "0")}:${"$second".padLeft(2, "0")}.${"$millisecond".padRight(3, "0")}";
  }

  void updateSpeed() {
    if (paused) {
      controller.setSpeed(0.00001);
      return;
    }
    final speed = switch (speedSelection) {
      Speed.x025 => 0.25,
      Speed.x050 => 0.50,
      Speed.x075 => 0.75,
      Speed.x100 => 1.00,
      Speed.x125 => 1.25,
    };
    controller.setSpeed(speed);
  }

  Widget _checkBoxTile({
    required bool value,
    required Function(bool?) onChanged,
    required Widget text,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Checkbox(value: value, onChanged: onChanged),
      text,
    ],
  );
}

enum Speed { x025, x050, x075, x100, x125 }
