part of 'shell.dart';

class _ShellSideMenu extends StatelessWidget {
  final _PhigrosChartPlayerShellViewModel viewModel;
  final Function() quitCallback;

  const _ShellSideMenu(this.viewModel, this.quitCallback);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = viewModel.controller;
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
                  valueListenable: viewModel.abStart,
                  builder: (_, abStart, _) =>
                      _infoRow("A-B Start", _formatTime(abStart), theme),
                ),
                ValueListenableBuilder(
                  valueListenable: viewModel.abEnd,
                  builder: (_, abEnd, _) =>
                      _infoRow("A-B End", _formatTime(abEnd), theme),
                ),
                const Divider(),
                ValueListenableBuilder(
                  valueListenable: viewModel.formatVersion,
                  builder: (_, formatVersion, _) =>
                      _infoRow("Chart format version", "$formatVersion", theme),
                ),
                ValueListenableBuilder(
                  valueListenable: viewModel.offset,
                  builder: (_, offset, _) =>
                      _infoRow("Chart offset(s)", "$offset", theme),
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
                  builder: (_, bufferUsage, _) => ValueListenableBuilder(
                    valueListenable: viewModel.bufferSize,
                    builder: (_, bufferSize, _) => _infoRow(
                      "Pre-render buffer usage",
                      "$bufferUsage/$bufferSize B",
                      theme,
                    ),
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: controller.logBufferUsage,
                  builder: (_, bufferUsage, _) => ValueListenableBuilder(
                    valueListenable: viewModel.bufferSize,
                    builder: (_, bufferSize, _) => LinearProgressIndicator(
                      value: bufferSize != 0 ? bufferUsage / bufferSize : 0,
                    ),
                  ),
                ),
                const Divider(),
                ValueListenableBuilder(
                  valueListenable: viewModel.enableTouch,
                  builder: (_, enableTouch, _) => SwitchListTile(
                    title: const Text("锁屏可打"),
                    subtitle: Text(
                      enableTouch ? "自动播放模式将在锁定屏幕时关闭" : "自动播放模式始终打开",
                    ),
                    value: enableTouch,
                    onChanged: (v) {
                      viewModel.enableTouch.value = v;
                      controller.setAutoPlay(
                        v ? !viewModel.isLocked.value : true,
                      );
                    },
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: viewModel.hitSound,
                  builder: (_, hitSound, _) => SwitchListTile(
                    title: const Text("打击音效"),
                    value: hitSound,
                    onChanged: (v) {
                      viewModel.hitSound.value = v;
                      controller.setEnableSound(v);
                    },
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: viewModel.highlight,
                  builder: (_, highlight, _) => SwitchListTile(
                    title: const Text("多押高亮"),
                    value: highlight,
                    onChanged: (v) {
                      viewModel.highlight.value = v;
                      controller.setHighlight(v);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton(
              onPressed: quitCallback,
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
}
