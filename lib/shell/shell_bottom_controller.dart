part of 'shell.dart';

class _ShellBottomController extends StatefulWidget {
  final _PhigrosChartPlayerShellViewModel viewModel;
  final _PhigrosChartPlayerShellState state;

  const _ShellBottomController(this.viewModel, this.state);

  @override
  State<StatefulWidget> createState() => _ShellBottomControllerState();
}

class _ShellBottomControllerState extends State<_ShellBottomController> {
  double _slideTime = 0;
  bool _sliding = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final state = widget.state;
    final colorTheme = Theme.of(context);
    final controller = viewModel.controller;
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
                state._onUserInteraction();
                if (controller.logTime.value >= viewModel.totalTime.value) {
                  controller.setTime(0);
                  viewModel.paused.value = false;
                } else {
                  viewModel.paused.value = !viewModel.paused.value;
                }
                state._updateSpeed();
              },
              icon: ValueListenableBuilder(
                valueListenable: viewModel.paused,
                builder: (_, paused, _) => Icon(
                  viewModel.paused.value ? Icons.play_arrow_sharp : Icons.pause,
                  color: Colors.white,
                ),
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
                    value: (_sliding ? _slideTime : time).clamp(
                      0,
                      viewModel.totalTime.value,
                    ),
                    max: viewModel.totalTime.value > 0
                        ? viewModel.totalTime.value
                        : 1.0,
                    onChangeStart: (v) {
                      state._onUserInteraction();
                      setState(() {
                        _sliding = true;
                        _slideTime = time;
                      });
                      state._hideTimer?.cancel();
                    },
                    onChanged: (v) {
                      controller.setTime(v);
                      _slideTime = v;
                    },
                    onChangeEnd: (v) {
                      state._onUserInteraction();
                      controller.setTime(v);
                      _sliding = false;
                      _slideTime = v;
                    },
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: controller.logTime,
              builder: (_, time, _) => Text(
                "${_formatTime((_sliding ? _slideTime : time).clamp(0, viewModel.totalTime.value))} / ${_formatTime(viewModel.totalTime.value)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder(
              valueListenable: viewModel.abStart,
              builder: (_, abStartV, _) => ValueListenableBuilder(
                valueListenable: viewModel.abEnd,
                builder: (_, abEndV, _) => IconButton(
                  onPressed: () {
                    state._onUserInteraction();
                    if (abEndV == null) {
                      if (abStartV == null) {
                        viewModel.abStart.value = controller.logTime.value;
                        return;
                      }
                      viewModel.abEnd.value = controller.logTime.value;
                      return;
                    }
                    viewModel.abEnd.value = null;
                    viewModel.abStart.value = null;
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
              child: ValueListenableBuilder(
                valueListenable: viewModel.speedSelection,
                builder: (_, speedSelection, _) => DropdownButton<Speed>(
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
                    state._onUserInteraction();
                    viewModel.speedSelection.value = v ?? Speed.x100;
                    state._updateSpeed();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
