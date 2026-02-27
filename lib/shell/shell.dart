import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:phasetida_flutter/phasetida_flutter.dart';
import 'package:phasetida_flutter/simulator/simulator.dart';

part 'shell_bottom_controller.dart';
part 'shell_gesture.dart';
part 'shell_side_menu.dart';
part 'shell_top_bar.dart';
part 'shell_util.dart';

class PhigrosChartPlayerShellWidget extends StatefulWidget {
  final String jsonData;
  final String songName;
  final String author;
  final String chartComposer;
  final Uint8List songBuffer;
  final Function() quitCallback;

  const PhigrosChartPlayerShellWidget({
    super.key,
    required this.jsonData,
    required this.songName,
    required this.author,
    required this.chartComposer,
    required this.quitCallback,
    required this.songBuffer,
  });

  @override
  State<StatefulWidget> createState() => _PhigrosChartPlayerShellState();
}

class _PhigrosChartPlayerShellViewModel {
  final controller = PhigrosSimulatorRenderController();

  ValueNotifier<double?> abStart = ValueNotifier(null);
  ValueNotifier<double?> abEnd = ValueNotifier(null);
  ValueNotifier<bool> enableTouch = ValueNotifier(true);
  ValueNotifier<bool> highlight = ValueNotifier(true);
  ValueNotifier<bool> hitSound = ValueNotifier(true);
  ValueNotifier<int> formatVersion = ValueNotifier(-1);
  ValueNotifier<double> offset = ValueNotifier(0.0);
  ValueNotifier<int> bufferSize = ValueNotifier(-1);
  ValueNotifier<double> totalTime = ValueNotifier(0.0);
  ValueNotifier<bool> isLocked = ValueNotifier(false);
  ValueNotifier<bool> showControls = ValueNotifier(true);
  ValueNotifier<bool> paused = ValueNotifier(false);
  ValueNotifier<Speed> speedSelection = ValueNotifier(Speed.x100);
  ValueNotifier<bool> isLongPressing = ValueNotifier(false);
}

class _PhigrosChartPlayerShellState extends State<PhigrosChartPlayerShellWidget>
    with SingleTickerProviderStateMixin {
  final _PhigrosChartPlayerShellViewModel _viewModel =
      _PhigrosChartPlayerShellViewModel();

  Ticker? _abTicker;

  Timer? _hideTimer;

  Timer? _rewindTimer;
  Timer? _fastForwardTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    _abTicker = createTicker((_) {
      final time = _viewModel.controller.logTime.value;
      final abStartV = _viewModel.abStart.value;
      final abEndV = _viewModel.abEnd.value;
      final totalTime = _viewModel.totalTime.value;
      if (totalTime == 0 || abStartV == null || abEndV == null) {
        return;
      }
      if (time >= abEndV) {
        _viewModel.controller.setTime(abStartV);
      }
      if (time < abStartV) {
        _viewModel.controller.setTime(abStartV);
      }
    })..start();
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
        _viewModel.showControls.value = false;
      }
    });
  }

  void _onUserInteraction() {
    if (!_viewModel.showControls.value) {
      _viewModel.showControls.value = true;
    }
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        endDrawer: Drawer(
          child: _ShellSideMenu(_viewModel, widget.quitCallback),
        ),
        endDrawerEnableOpenDragGesture: false,
        body: RepaintBoundary(
          child: ValueListenableBuilder(
            valueListenable: _viewModel.controller.isLoading,
            builder: (_, isLoading, _) => ValueListenableBuilder(
              valueListenable: _viewModel.controller.loadError,
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
      ),
    );
  }

  Widget _loadingBody(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(16),
      child: Stack(
        children: [
          Center(
            child: _viewModel.controller.loadError.value == null
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
                        "${_viewModel.controller.loadError.value}",
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
              controller: _viewModel.controller,
              levelJson: widget.jsonData,
              songBuffer: widget.songBuffer,
              onLoad: (totalTime, offset, formatVersion, bufferSize) {
                _viewModel.totalTime.value = totalTime;
                _viewModel.offset.value = offset;
                _viewModel.formatVersion.value = formatVersion;
                _viewModel.bufferSize.value = bufferSize;
              },
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _viewModel.controller.logTime,
          builder: (_, time, _) => ValueListenableBuilder(
            valueListenable: _viewModel.totalTime,
            builder: (_, totalTime, _) => Positioned(
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
        ),
        ValueListenableBuilder(
          valueListenable: _viewModel.controller.logCombo,
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
            valueListenable: _viewModel.controller.logScore,
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
        Positioned.fill(child: _ShellGesture(_viewModel, this)),
        ValueListenableBuilder(
          valueListenable: _viewModel.isLocked,
          builder: (_, isLocked, _) => ValueListenableBuilder(
            valueListenable: _viewModel.showControls,
            builder: (_, showControls, _) => Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: (!isLocked && showControls) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: isLocked || !showControls,
                  child: _ShellTopBar(_viewModel, this),
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _viewModel.isLocked,
          builder: (_, isLocked, _) => ValueListenableBuilder(
            valueListenable: _viewModel.showControls,
            builder: (_, showControls, _) => Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: (!isLocked && showControls) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: isLocked || !showControls,
                  child: _ShellBottomController(_viewModel, this),
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _viewModel.isLocked,
          builder: (_, isLocked, _) => ValueListenableBuilder(
            valueListenable: _viewModel.showControls,
            builder: (_, showControls, _) => Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !showControls,
                    child: IconButton(
                      onPressed: () {
                        _onUserInteraction();
                        _viewModel.isLocked.value = !isLocked;
                        _viewModel.controller.setAutoPlay(
                          _viewModel.enableTouch.value
                              ? !_viewModel.isLocked.value
                              : true,
                        );
                      },
                      icon: Icon(
                        isLocked ? Icons.lock_outline : Icons.lock_open,
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
          ),
        ),
      ],
    );
  }

  void _updateSpeed() {
    final paused = _viewModel.paused.value;
    _viewModel.controller.setPaused(paused);
    if (paused) {
      return;
    }
    if (_viewModel.isLongPressing.value) {
      _viewModel.controller.setSpeed(2.0);
      return;
    }
    final speed = switch (_viewModel.speedSelection.value) {
      Speed.x025 => 0.25,
      Speed.x050 => 0.50,
      Speed.x075 => 0.75,
      Speed.x100 => 1.00,
      Speed.x125 => 1.25,
    };
    _viewModel.controller.setSpeed(speed);
  }
}

enum Speed { x025, x050, x075, x100, x125 }
