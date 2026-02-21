part of 'shell.dart';

class _ShellTopBar extends StatelessWidget {
  final _PhigrosChartPlayerShellState state;
  final _PhigrosChartPlayerShellViewModel viewModel;

  const _ShellTopBar(this.viewModel, this.state);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final widget = state.widget;
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
            ValueListenableBuilder(
              valueListenable: viewModel.controller.soundError,
              builder: (_, error, _) => error == null
                  ? SizedBox.shrink()
                  : IconButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("一些小差错..."),
                            content: Text(
                              "抱歉，音频加载失败了...\n谱面的图形预览仍然可以观看，如果可以的话，请在GitHub上发起issue",
                            ),
                            actions: [
                              TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text:
                                          "${widget.songName}/${widget.author}/${widget.chartComposer}\n$error\n${_uint8ListToHex(widget.songBuffer)}",
                                    ),
                                  );
                                },
                                label: Text("复制错误报告"),
                                icon: Icon(Icons.copy),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.warning, color: Colors.white),
                    ),
            ),
            Builder(
              builder: (context) => IconButton(
                onPressed: () {
                  state._onUserInteraction();
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

  String _uint8ListToHex(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ')
        .toUpperCase();
  }
}
