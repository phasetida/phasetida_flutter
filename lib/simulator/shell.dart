import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:phasetida_flutter/phasetida_flutter.dart';
import 'package:phasetida_flutter/simulator/simulator.dart';

class PhigrosChartPlayerShellWidget extends StatefulWidget {
  final String jsonData;
  final String songName;
  final String author;
  final String chartComposer;
  final Function() quitCallback;

  const PhigrosChartPlayerShellWidget({
    super.key,
    required this.jsonData,
    required this.songName,
    required this.author,
    required this.chartComposer,
    required this.quitCallback,
  });

  @override
  State<StatefulWidget> createState() => _PhigrosChartPlayerShellState();
}

class _PhigrosChartPlayerShellState extends State<PhigrosChartPlayerShellWidget>
    with SingleTickerProviderStateMixin {
  final controller = PhigrosSimulatorRenderController();
  bool auto = true;
  bool highlight = true;
  bool hitSound = true;

  double totalTime = 0.0;

  double slideTime = 0;
  bool sliding = false;

  Speed speedSelection = Speed.x100;
  bool paused = false;

  Ticker? _abTicker;
  ValueNotifier<double?> abStart = ValueNotifier(null);
  ValueNotifier<double?> abEnd = ValueNotifier(null);

  int bufferSize = 0;

  bool _showControls = true;
  bool _isLocked = false;
  Timer? _hideTimer;

  bool _isLongPressing = false;
  bool _showRewind = false;
  bool _showFastForward = false;
  Timer? _rewindTimer;
  Timer? _fastForwardTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    _abTicker = createTicker((_) {
      final time = controller.logTime.value;
      final abStartV = abStart.value;
      final abEndV = abEnd.value;
      if (totalTime == 0 || abStartV == null || abEndV == null) {
        return;
      }
      if (time >= abEndV) {
        controller.setTime(abStartV);
      }
      if (time < abStartV) {
        controller.setTime(abStartV);
      }
    })..start();
  }

  void _showRewindIndicator() {
    setState(() {
      _showRewind = true;
    });
    _rewindTimer?.cancel();
    _rewindTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showRewind = false;
        });
      }
    });
  }

  void _showFastForwardIndicator() {
    setState(() {
      _showFastForward = true;
    });
    _fastForwardTimer?.cancel();
    _fastForwardTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showFastForward = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _rewindTimer?.cancel();
    _fastForwardTimer?.cancel();
    _abTicker?.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _onUserInteraction() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      endDrawer: Drawer(child: _sideMenu(context)),
      body: RepaintBoundary(
        child: ValueListenableBuilder(
          valueListenable: controller.isLoading,
          builder: (_, isLoading, _) => ValueListenableBuilder(
            valueListenable: controller.loadError,
            builder: (_, loadError, _) => AnimatedCrossFade(
              crossFadeState: (isLoading || loadError != null)
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: Duration(milliseconds: 250),
              firstChild: _loadingBody(context),
              secondChild: _playerBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingBody(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(16),
      child: Stack(
        children: [
          Center(
            child: controller.loadError.value == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text("少女祈祷中...", style: TextStyle(color: Colors.white)),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        "Phasetida has encountered a problem!",
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        "${controller.loadError.value}",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
          ),
          IconButton(
            onPressed: widget.quitCallback,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _playerBody(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1920.0 / 1080.0,
            child: PhigrosSimulatorRenderWidget(
              controller: controller,
              levelJson: widget.jsonData,
              onLoad: (totalTime, bufferSize) {
                setState(() {
                  this.totalTime = totalTime;
                  this.bufferSize = bufferSize;
                });
              },
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.logTime,
          builder: (_, time, _) => Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 4,
            child: LinearProgressIndicator(
              value: totalTime > 0 ? (time / totalTime).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: controller.logCombo,
          builder: (_, combo, _) => combo >= 3
              ? Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          combo.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black54,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          "COMBO",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black54,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ),
        Positioned(
          top: 12,
          right: 16,
          child: ValueListenableBuilder(
            valueListenable: controller.logScore,
            builder: (_, score, _) => Text(
              score.toStringAsFixed(0).padLeft(7, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black54,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  onDoubleTap: () {
                    if (_isLocked) return;
                    _onUserInteraction();
                    controller.setTime(
                      (controller.logTime.value - 3.0).clamp(0, totalTime),
                    );
                    _showRewindIndicator();
                    HapticFeedback.lightImpact();
                  },
                  onLongPressStart: (_) {
                    if (_isLocked) return;
                    _isLongPressing = true;
                    controller.setSpeed(2.0);
                    HapticFeedback.selectionClick();
                  },
                  onLongPressEnd: (_) {
                    if (_isLocked) return;
                    _isLongPressing = false;
                    updateSpeed();
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  onDoubleTap: () {
                    if (_isLocked) return;
                    _onUserInteraction();
                    setState(() {
                      if (controller.logTime.value >= totalTime) {
                        controller.setTime(0);
                        paused = false;
                      } else {
                        paused = !paused;
                      }
                    });
                    updateSpeed();
                    HapticFeedback.lightImpact();
                  },
                  onLongPressStart: (_) {
                    if (_isLocked) return;
                    _isLongPressing = true;
                    controller.setSpeed(2.0);
                    HapticFeedback.selectionClick();
                  },
                  onLongPressEnd: (_) {
                    if (_isLocked) return;
                    _isLongPressing = false;
                    updateSpeed();
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  onDoubleTap: () {
                    if (_isLocked) return;
                    _onUserInteraction();
                    controller.setTime(
                      (controller.logTime.value + 3.0).clamp(0, totalTime),
                    );
                    _showFastForwardIndicator();
                    HapticFeedback.lightImpact();
                  },
                  onLongPressStart: (_) {
                    if (_isLocked) return;
                    _isLongPressing = true;
                    controller.setSpeed(2.0);
                    HapticFeedback.selectionClick();
                  },
                  onLongPressEnd: (_) {
                    if (_isLocked) return;
                    _isLongPressing = false;
                    updateSpeed();
                    HapticFeedback.selectionClick();
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: (!_isLocked && _showControls) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: _isLocked || !_showControls,
              child: _topBar(context),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: (!_isLocked && _showControls) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: _isLocked || !_showControls,
              child: _bottomController(context),
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: IconButton(
                  onPressed: () {
                    _onUserInteraction();
                    setState(() {
                      _isLocked = !_isLocked;
                    });
                  },
                  icon: Icon(
                    _isLocked ? Icons.lock_outline : Icons.lock_open,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isLongPressing)
          const Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Chip(
                backgroundColor: Colors.black54,
                label: Text("2x Speed", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        if (_showRewind)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width / 3,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fast_rewind, color: Colors.white, size: 48),
                  Text(
                    "-3s",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_showFastForward)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width / 3,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fast_forward, color: Colors.white, size: 48),
                  Text(
                    "+3s",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _topBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: widget.quitCallback,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.songName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${widget.author} / ${widget.chartComposer}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                onPressed: () {
                  _onUserInteraction();
                  Scaffold.of(context).openEndDrawer();
                },
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomController(BuildContext context) {
    final colorTheme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                _onUserInteraction();
                setState(() {
                  if (controller.logTime.value >= totalTime) {
                    controller.setTime(0);
                    paused = false;
                  } else {
                    paused = !paused;
                  }
                  updateSpeed();
                });
              },
              icon: Icon(
                paused ? Icons.play_arrow_sharp : Icons.pause,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  activeTrackColor: colorTheme.primaryColor,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                ),
                child: ValueListenableBuilder(
                  valueListenable: controller.logTime,
                  builder: (_, time, _) => Slider(
                    value: (sliding ? slideTime : time).clamp(0, totalTime),
                    max: totalTime > 0 ? totalTime : 1.0,
                    onChangeStart: (v) {
                      _onUserInteraction();
                      setState(() {
                        sliding = true;
                        slideTime = time;
                      });
                      _hideTimer?.cancel();
                    },
                    onChanged: (v) {
                      controller.setTime(v);
                      slideTime = v;
                    },
                    onChangeEnd: (v) {
                      _onUserInteraction();
                      controller.setTime(v);
                      sliding = false;
                      slideTime = v;
                    },
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: controller.logTime,
              builder: (_, time, _) => Text(
                "${_formatTime((sliding ? slideTime : time).clamp(0, totalTime))} / ${_formatTime(totalTime)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder(
              valueListenable: abStart,
              builder: (_, abStartV, _) => ValueListenableBuilder(
                valueListenable: abEnd,
                builder: (_, abEndV, _) => IconButton(
                  onPressed: () {
                    _onUserInteraction();
                    if (abEndV == null) {
                      if (abStartV == null) {
                        abStart.value = controller.logTime.value;
                        return;
                      }
                      abEnd.value = controller.logTime.value;
                      return;
                    }
                    abEnd.value = null;
                    abStart.value = null;
                  },
                  icon: Icon(
                    abEndV != null && abStartV != null
                        ? Icons.repeat_on
                        : Icons.repeat,
                    color: abEndV == null
                        ? abStartV == null
                              ? Colors.white54
                              : Colors.white
                        : colorTheme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.black87),
              child: DropdownButton<Speed>(
                icon: const Icon(Icons.speed, color: Colors.white),
                isDense: true,
                underline: const SizedBox.shrink(),
                dropdownColor: Colors.black87,
                style: const TextStyle(color: Colors.white),
                value: speedSelection,
                items: const [
                  DropdownMenuItem(value: Speed.x025, child: Text("x.25")),
                  DropdownMenuItem(value: Speed.x050, child: Text("x.50")),
                  DropdownMenuItem(value: Speed.x075, child: Text("x.75")),
                  DropdownMenuItem(value: Speed.x100, child: Text("x1.0")),
                  DropdownMenuItem(value: Speed.x125, child: Text("x1.25")),
                ],
                onChanged: (v) {
                  _onUserInteraction();
                  setState(() {
                    speedSelection = v ?? Speed.x100;
                  });
                  updateSpeed();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideMenu(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("详细信息", style: theme.textTheme.headlineSmall),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ValueListenableBuilder(
                  valueListenable: controller.logScore,
                  builder: (_, score, _) =>
                      _infoRow("Score", score.toStringAsFixed(0), theme),
                ),
                ValueListenableBuilder(
                  valueListenable: controller.logCombo,
                  builder: (_, combo, _) => ValueListenableBuilder(
                    valueListenable: controller.logMaxCombo,
                    builder: (_, maxCombo, _) => _infoRow(
                      "Combo",
                      "${combo.toStringAsFixed(0)}/${maxCombo.toStringAsFixed(0)}",
                      theme,
                    ),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: controller.logAccurate,
                  builder: (_, accurate, _) => _infoRow(
                    "Accuracy",
                    "${(accurate * 100).toStringAsFixed(4)}%",
                    theme,
                  ),
                ),
                const Divider(),
                ValueListenableBuilder(
                  valueListenable: abStart,
                  builder: (_, abStart, _) =>
                      _infoRow("A-B Start", _formatTime(abStart), theme),
                ),

                ValueListenableBuilder(
                  valueListenable: abEnd,
                  builder: (_, abEnd, _) =>
                      _infoRow("A-B End", _formatTime(abEnd), theme),
                ),
                const Divider(),
                _infoRow(
                  "phasetida_flutter version",
                  phasetidaFlutterVersion,
                  theme,
                ),
                _infoRow("phasetida-core version", phasetidaCoreVersion, theme),
                ValueListenableBuilder(
                  valueListenable: controller.logBufferUsage,
                  builder: (_, bufferUsage, _) => _infoRow(
                    "Pre-render buffer usage",
                    "$bufferUsage/$bufferSize B",
                    theme,
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: controller.logBufferUsage,
                  builder: (_, bufferUsage, _) => LinearProgressIndicator(
                    value: bufferSize != 0 ? bufferUsage / bufferSize : 0,
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text("打击音效"),
                  value: hitSound,
                  onChanged: (v) {
                    setState(() {
                      hitSound = v;
                    });
                    controller.setEnableSound(hitSound);
                  },
                ),
                // SwitchListTile(
                //   title: const Text("自动播放"),
                //   value: auto,
                //   onChanged: (v) {
                //     setState(() {
                //       auto = v;
                //     });
                //     controller.setAutoPlay(auto);
                //   },
                // ),
                if (!auto)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "注：非自动播放为实验性功能，在部分设备上会出现触控问题",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                SwitchListTile(
                  title: const Text("多押高亮"),
                  value: highlight,
                  onChanged: (v) {
                    setState(() {
                      highlight = v;
                    });
                    controller.setHighlight(highlight);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: widget.quitCallback,
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text("退出铺面预览")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  String _formatTime(double? time) {
    if (time == null) return "-";
    if (time.isNaN || time.isInfinite) return "-";
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
    if (_isLongPressing) {
      controller.setSpeed(2.0);
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
}

enum Speed { x025, x050, x075, x100, x125 }
