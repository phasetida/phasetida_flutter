part of 'shell.dart';

class _ShellGesture extends StatefulWidget {
  final _PhigrosChartPlayerShellViewModel viewModel;
  final _PhigrosChartPlayerShellState state;

  const _ShellGesture(this.viewModel, this.state);

  @override
  State<StatefulWidget> createState() => _ShellGestureState();
}

class _ShellGestureState extends State<_ShellGesture> {
  bool _showRewind = false;
  bool _showFastForward = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final state = widget.state;
    return ValueListenableBuilder(
      valueListenable: viewModel.isLocked,
      builder: (_, isLocked, _) => ValueListenableBuilder(
        valueListenable: viewModel.showControls,
        builder: (_, showControls, _) => Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _toggleControls,
                      onDoubleTap: () {
                        if (isLocked) return;
                        state._onUserInteraction();
                        viewModel.controller.setTime(
                          (viewModel.controller.logTime.value - 3.0).clamp(
                            0,
                            viewModel.totalTime.value,
                          ),
                        );
                        _showRewindIndicator();
                        HapticFeedback.lightImpact();
                      },
                      onLongPressStart: (_) {
                        if (isLocked) return;
                        viewModel.isLongPressing.value = true;
                        viewModel.controller.setSpeed(2.0);
                        HapticFeedback.selectionClick();
                      },
                      onLongPressEnd: (_) {
                        if (isLocked) return;
                        viewModel.isLongPressing.value = false;
                        state._updateSpeed();
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _toggleControls,
                      onDoubleTap: () {
                        if (isLocked) return;
                        state._onUserInteraction();
                        if (viewModel.controller.logTime.value >=
                            viewModel.totalTime.value) {
                          viewModel.controller.setTime(0);
                          viewModel.paused.value = false;
                        } else {
                          viewModel.paused.value = !viewModel.paused.value;
                        }
                        state._updateSpeed();
                        HapticFeedback.lightImpact();
                      },
                      onLongPressStart: (_) {
                        if (isLocked) return;
                        viewModel.isLongPressing.value = true;
                        viewModel.controller.setSpeed(2.0);
                        HapticFeedback.selectionClick();
                      },
                      onLongPressEnd: (_) {
                        if (isLocked) return;
                        viewModel.isLongPressing.value = false;
                        state._updateSpeed();
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _toggleControls,
                      onDoubleTap: () {
                        if (isLocked) return;
                        state._onUserInteraction();
                        viewModel.controller.setTime(
                          (viewModel.controller.logTime.value + 3.0).clamp(
                            0,
                            viewModel.totalTime.value,
                          ),
                        );
                        _showFastForwardIndicator();
                        HapticFeedback.lightImpact();
                      },
                      onLongPressStart: (_) {
                        if (isLocked) return;
                        viewModel.isLongPressing.value = true;
                        viewModel.controller.setSpeed(2.0);
                        HapticFeedback.selectionClick();
                      },
                      onLongPressEnd: (_) {
                        if (isLocked) return;
                        viewModel.isLongPressing.value = false;
                        state._updateSpeed();
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: viewModel.isLongPressing,
              builder: (_, isLongPressing, _) => isLongPressing
                  ? const Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Chip(
                          backgroundColor: Colors.black54,
                          label: Text(
                            "2x Speed",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
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
        ),
      ),
    );
  }

  void _toggleControls() {
    final viewModel = widget.viewModel;
    final state = widget.state;
    viewModel.showControls.value = !viewModel.showControls.value;
    if (viewModel.showControls.value) {
      state._startHideTimer();
    } else {
      state._hideTimer?.cancel();
    }
  }

  void _showRewindIndicator() {
    final state = widget.state;
    setState(() {
      _showRewind = true;
    });
    state._rewindTimer?.cancel();
    state._rewindTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showRewind = false;
        });
      }
    });
  }

  void _showFastForwardIndicator() {
    final state = widget.state;
    setState(() {
      _showFastForward = true;
    });
    state._fastForwardTimer?.cancel();
    state._fastForwardTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showFastForward = false;
        });
      }
    });
  }
}
