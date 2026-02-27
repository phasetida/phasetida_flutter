import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:phasetida_flutter_example/api/api.dart';
import 'package:phasetida_flutter_example/api/info_json.dart';
import 'package:phasetida_flutter_example/widget/simulator_widget.dart';

class SongCardWidget extends StatefulWidget {
  final Song song;

  const SongCardWidget({super.key, required this.song});

  @override
  State<StatefulWidget> createState() => SongCardWidgetState();
}

class SongCardWidgetState extends State<SongCardWidget> {
  bool _expand = false;
  bool _downloading = false;
  String _downloadDifficulty = "EZ";
  Level? _downloadLevel;

  Future<void> download() async {
    final result = await TaskEither<void, (String, Uint8List)>.Do(($) async {
      final song = widget.song;
      final chart = await $(
        SomniaApi.instance.getChart(song.id, _downloadDifficulty),
      );
      final songData = await $(SomniaApi.instance.getSong(song.id));
      return (chart, songData);
    }).run();
    switch (result) {
      case Right(value: final it):
        final (chart, songData) = it;
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SimulatorWidget(
                levelData: chart,
                songData: songData,
                songInfo: widget.song,
                levelInfo: _downloadLevel!,
              ),
            ),
          );
        }
      case Left():
    }
    setState(() {
      _downloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final song = widget.song;
    final level = song.levels;
    final difficultMap = [
      (level.easy != null, Color(0xFF689F38), "EZ", level.easy),
      (level.hard != null, Color(0xFF0288D1), "HD", level.hard),
      (level.insane != null, Color(0xFFD32F2F), "IN", level.insane),
      (level.another != null, Color(0xFF455A64), "AT", level.another),
    ];
    return AbsorbPointer(
      absorbing: _downloading,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: AnimatedSize(
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
          child: InkWell(
            onTap: () {
              setState(() {
                _expand = !_expand;
              });
            },
            child: Padding(
              padding: EdgeInsetsGeometry.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.name,
                              style: textTheme.titleMedium,
                              overflow: TextOverflow.fade,
                            ),
                            Text(
                              song.id,
                              style: textTheme.titleSmall,
                              overflow: TextOverflow.fade,
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.tight,
                        flex: 0,
                        child: Row(
                          spacing: 4,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: difficultMap.filter((it) => it.$1).map((
                            it,
                          ) {
                            return Container(
                              decoration: ShapeDecoration(
                                shape: CircleBorder(),
                                color: it.$2,
                              ),
                              child: SizedBox.square(dimension: 16),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  _box(
                    show: _expand,
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        Row(
                          spacing: 4,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...difficultMap
                                .filter((it) => it.$1)
                                .map(
                                  (it) => Flexible(
                                    flex: 1,
                                    fit: FlexFit.tight,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _expand = false;
                                          _downloading = true;
                                        });
                                        _downloadLevel = it.$4;
                                        _downloadDifficulty = it.$3;
                                        download();
                                      },
                                      label: Text(it.$3),
                                      icon: Icon(Icons.play_arrow),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _box(
                    show: _downloading,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _box({required bool show, required Widget child}) =>
      show ? child : SizedBox.shrink(child: child);
}
