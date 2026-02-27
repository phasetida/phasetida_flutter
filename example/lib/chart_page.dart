import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:phasetida_flutter_example/api/api.dart';
import 'package:phasetida_flutter_example/api/info_json.dart';
import 'package:phasetida_flutter_example/util/dio_util.dart' as dio_util;
import 'package:phasetida_flutter_example/util/json_util.dart' as json_util;
import 'package:phasetida_flutter_example/widget/simulator_widget.dart';
import 'package:phasetida_flutter_example/widget/song_card.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<StatefulWidget> createState() => ChartPageState();
}

sealed class _LoadingState {}

class _StateLoading extends _LoadingState {}

class _StateSuccess extends _LoadingState {
  AllInfo allInfo;

  _StateSuccess(this.allInfo);
}

class _StateFailed extends _LoadingState {
  Either<json_util.JsonFailure, dio_util.DioFailure> error;

  _StateFailed(this.error);
}

class ChartPageState extends State<ChartPage> {
  _LoadingState _state = _StateLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = _StateLoading();
    });
    final allInfo = await SomniaApi.instance.getAllInfo().run();
    switch (allInfo) {
      case Right(value: final it):
        {
          setState(() {
            _state = _StateSuccess(it);
          });
        }
      case Left(value: final it):
        {
          setState(() {
            _state = _StateFailed(it);
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 250),
      child: switch (_state) {
        _StateLoading _ => _loadingPage(),
        _StateSuccess it => _chartListPage(it),
        _StateFailed it => _failedPage(it),
      },
    );
  }

  Widget _chartListPage(_StateSuccess result) {
    return ListView(
      children: result.allInfo.songs
          .map((it) => SongCardWidget(song: it))
          .toList(),
    );
  }

  Widget _loadingPage() {
    return Center(key: Key("loading"), child: CircularProgressIndicator());
  }

  Widget _failedPage(_StateFailed failure) {
    final (icon, message) = _selectErrorMessage(failure);
    return Center(
      key: Key("failed"),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          SizedBox(height: 8),
          Text(message),
          Text("可以尝试刷新，或观看本地示例"),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () {
                  _load();
                },
                icon: Icon(Icons.refresh),
                label: Text("重试"),
              ),
              TextButton.icon(
                onPressed: () {
                  _showLocalExample();
                },
                icon: Icon(Icons.sd_storage),
                label: Text("本地示例"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 什么？你怎么知道我懒得给example做本地化了？
  (IconData, String) _selectErrorMessage(_StateFailed failure) =>
      switch (failure.error) {
        Right<json_util.JsonFailure, dio_util.DioFailure>(value: final it) =>
          switch (it) {
            dio_util.NetworkFailure() => (
              Icons.wifi_off,
              "网络出了一点问题……可以尝试切换网络环境后重试……你懂的！",
            ),
            dio_util.BadCertificateFailure() => (Icons.key_off, "证书出错啦……"),
            dio_util.BadResponseFailure() => (
              Icons.cloud_off,
              "服务器返回了一个错误的响应……去问问弦塔吧……",
            ),
            dio_util.UnknownFailure(message: final message) => (
              Icons.error,
              "未知的dio错误：$message",
            ),
          },
        Left<json_util.JsonFailure, dio_util.DioFailure>(value: final it) => (
          Icons.error,
          "什么？Json解析失败了？肯定又是弦塔偷偷改Json结构了！乆乆乆\n${it.message}",
        ),
      };

  Future<void> _showLocalExample() async {
    final levelInfo = Level("Unknown", 0, 0);
    final songInfo = Song(
      "Unknown",
      "Unknown",
      "Unknown",
      Levels(null, null, null, null),
    );
    final levelData = await rootBundle.loadString("assets/test.json");
    final songData = (await rootBundle.load(
      "assets/test.ogg",
    )).buffer.asUint8List();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SimulatorWidget(
            levelData: levelData,
            songData: songData,
            songInfo: songInfo,
            levelInfo: levelInfo,
          ),
        ),
      );
    }
  }
}
