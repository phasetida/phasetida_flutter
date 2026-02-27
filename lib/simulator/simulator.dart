import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:buffer/buffer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:phasetida_flutter/simulator/input_container.dart';
import 'package:phasetida_flutter/src/rust/api/phasetida.dart' as phasetida;

part 'painter.dart';

class PhigrosSimulatorRenderWidget extends StatefulWidget {
  final PhigrosSimulatorRenderController controller;
  final void Function(
    double totalTime,
    double offset,
    int formatVersion,
    int bufferSize,
  )?
  onLoad;
  final String levelJson;
  final Uint8List songBuffer;

  const PhigrosSimulatorRenderWidget({
    super.key,
    required this.controller,
    required this.levelJson,
    required this.songBuffer,
    this.onLoad,
  });

  @override
  State<StatefulWidget> createState() => _PhigrosSimulatorRenderWidgetState();
}

class PhigrosSimulatorRenderController {
  PainterController? _painterController;

  ValueNotifier<double> logTime = ValueNotifier(0);
  ValueNotifier<int> logCombo = ValueNotifier(0);
  ValueNotifier<int> logMaxCombo = ValueNotifier(0);
  ValueNotifier<double> logScore = ValueNotifier(0);
  ValueNotifier<double> logAccurate = ValueNotifier(0);
  ValueNotifier<int> logBufferUsage = ValueNotifier(0);
  ValueNotifier<bool> isLoading = ValueNotifier(true);
  ValueNotifier<String?> loadError = ValueNotifier(null);
  ValueNotifier<String?> soundError = ValueNotifier(null);

  StreamController<double> musicTimeController = StreamController();
  StreamController<double> musicSpeedController = StreamController();
  StreamController<bool> musicPauseController = StreamController();

  bool _enableSound = true;

  void setTime(double time) {
    _painterController?.setTime(time);
    setMusicTime(time);
  }

  void setMusicTime(double time) {
    musicTimeController.add(time);
  }

  void setSpeed(double speed) {
    _painterController?.setSpeed(speed);
    musicSpeedController.add(speed);
  }

  void setPaused(bool paused) {
    _painterController?.setPaused(paused);
    musicPauseController.add(paused);
  }

  void setAutoPlay(bool auto) {
    _painterController?._auto = auto;
    phasetida.resetTouchState();
  }

  void setHighlight(bool highlight) {
    _painterController?._showHighlight = highlight;
  }

  void setEnableSound(bool enableSound) {
    _enableSound = enableSound;
  }
}

class _PhigrosSimulatorRenderWidgetState
    extends State<PhigrosSimulatorRenderWidget>
    with SingleTickerProviderStateMixin {
  final _canvasKey = GlobalKey();

  _Painter? _painter;
  PainterController? painterController;

  InputContainer inputContainer = InputContainer();

  StreamSubscription<double>? musicTimeSub;
  StreamSubscription<double>? musicSpeedSub;
  StreamSubscription<bool>? musicPauseSub;

  Ticker? _reDrawTicker;

  AudioSource? tapSound;
  AudioSource? dragSound;
  AudioSource? flickSound;
  AudioSource? songSource;
  SoundHandle? songHandle;
  ui.Image? tapImage;
  ui.Image? tapHighlightImage;
  ui.Image? dragImage;
  ui.Image? dragHighlightImage;
  ui.Image? flickImage;
  ui.Image? flickHighlightImage;
  ui.Image? holdHeadImage;
  ui.Image? holdHeadHighlightImage;
  ui.Image? holdBodyImage;
  ui.Image? holdBodyHighlightImage;
  ui.Image? holdEndImage;
  List<ui.Image>? splashImages;
  List<ui.Image>? clickImages;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    phasetida.clearStates();
    double? musicTotalTime;
    double estTotalTime;
    double offset;
    int formatVersion;
    ui.Image tapImage;
    ui.Image tapHighlightImage;
    ui.Image dragImage;
    ui.Image dragHighlightImage;
    ui.Image flickImage;
    ui.Image flickHighlightImage;
    ui.Image holdHeadImage;
    ui.Image holdHeadHighlightImage;
    ui.Image holdBodyImage;
    ui.Image holdBodyHighlightImage;
    ui.Image holdEndImage;
    List<ui.Image> splashImages;
    List<ui.Image> clickImages;
    Duration? songLength;
    try {
      final metadata = phasetida.loadLevel(json: widget.levelJson);
      estTotalTime = metadata.$1;
      offset = metadata.$2;
      formatVersion = metadata.$3;
    } catch (e) {
      widget.controller.isLoading.value = false;
      widget.controller.loadError.value = "failed to load level: $e";
      return;
    }
    try {
      tapImage = await _loadImage("notes/tap.png");
      tapHighlightImage = await _loadImage("notes/tap_hl.png");
      dragImage = await _loadImage("notes/drag.png");
      dragHighlightImage = await _loadImage("notes/drag_hl.png");
      flickImage = await _loadImage("notes/flick.png");
      flickHighlightImage = await _loadImage("notes/flick_hl.png");
      holdHeadImage = await _loadImage("notes/hold_head.png");
      holdHeadHighlightImage = await _loadImage("notes/hold_head_hl.png");
      holdBodyImage = await _loadImage("notes/hold_body.png");
      holdBodyHighlightImage = await _loadImage("notes/hold_body_hl.png");
      holdEndImage = await _loadImage("notes/hold_end.png");
      splashImages = await Future.wait(
        List.generate(30, (i) async => _loadImage("splash/splash$i.png")),
      );
      clickImages = await Future.wait(
        List.generate(30, (i) async => _loadImage("clicks/click$i.png")),
      );
      this.tapImage = tapImage;
      this.tapHighlightImage = tapHighlightImage;
      this.dragImage = dragImage;
      this.dragHighlightImage = dragHighlightImage;
      this.flickImage = flickImage;
      this.flickHighlightImage = flickHighlightImage;
      this.holdHeadImage = holdHeadImage;
      this.holdHeadHighlightImage = holdHeadHighlightImage;
      this.holdBodyImage = holdBodyImage;
      this.holdBodyHighlightImage = holdBodyHighlightImage;
      this.holdEndImage = holdEndImage;
      this.splashImages = splashImages;
      this.clickImages = clickImages;
    } catch (e) {
      widget.controller.isLoading.value = false;
      widget.controller.loadError.value = "failed to load image: $e";
      return;
    }
    try {
      SoLoud.instance.setMaxActiveVoiceCount(16 * 3 + 2);
      final tapSound = await SoLoud.instance.loadAsset(
        "packages/phasetida_flutter/assets/sound/hitSong0.wav",
        mode: LoadMode.memory,
      );
      final dragSound = await SoLoud.instance.loadAsset(
        "packages/phasetida_flutter/assets/sound/hitSong1.wav",
        mode: LoadMode.memory,
      );
      final flickSound = await SoLoud.instance.loadAsset(
        "packages/phasetida_flutter/assets/sound/hitSong2.wav",
        mode: LoadMode.memory,
      );
      this.tapSound = tapSound;
      this.dragSound = dragSound;
      this.flickSound = flickSound;
    } catch (e) {
      widget.controller.soundError.value = "failed to load effect sound: $e";
    }
    try {
      final songSource = await SoLoud.instance.loadMem(
        "song.ogg",
        widget.songBuffer,
        mode: LoadMode.memory,
      );
      songLength = SoLoud.instance.getLength(songSource);
      musicTotalTime = songLength.inMilliseconds / 1000.0;
      final songHandle = await SoLoud.instance.play(
        songSource,
        paused: true,
        looping: true,
        loopingStartAt: songLength,
      );
      this.songSource = songSource;
      this.songHandle = songHandle;
    } catch (e) {
      widget.controller.soundError.value = "failed to load game sound: $e";
    }
    musicTimeSub = widget.controller.musicTimeController.stream.listen((time) {
      final songHandle = this.songHandle;
      if (songHandle != null && songLength != null) {
        final lengthInMillisecond = songLength.inMilliseconds - 5;
        SoLoud.instance.setPause(songHandle, false);
        SoLoud.instance.seek(
          songHandle,
          Duration(
            milliseconds: (time * 1000.0).toInt().clamp(0, lengthInMillisecond),
          ),
        );
      }
    });
    musicSpeedSub = widget.controller.musicSpeedController.stream.listen((
      speed,
    ) {
      final songHandle = this.songHandle;
      if (songHandle != null) {
        SoLoud.instance.setRelativePlaySpeed(songHandle, speed);
      }
    });
    musicPauseSub = widget.controller.musicPauseController.stream.listen((
      paused,
    ) {
      final songHandle = this.songHandle;
      if (songHandle != null) {
        SoLoud.instance.setPause(songHandle, paused);
      }
    });
    final painterController = PainterController(
      tapImage: tapImage,
      tapHighlightImage: tapHighlightImage,
      dragImage: dragImage,
      dragHighlightImage: dragHighlightImage,
      flickImage: flickImage,
      flickHighlightImage: flickHighlightImage,
      holdHeadImage: holdHeadImage,
      holdHeadHighlightImage: holdHeadHighlightImage,
      holdBodyImage: holdBodyImage,
      holdBodyHighlightImage: holdBodyHighlightImage,
      holdEndImage: holdEndImage,
      splashImages: splashImages,
      clickImages: clickImages,
      offset: offset,
      soundTick: (logTapSound, logDragSound, logFlickSound) {
        if (widget.controller._enableSound) {
          _playSound(tapSound, logTapSound);
          _playSound(dragSound, logDragSound);
          _playSound(flickSound, logFlickSound);
        }
      },
    );
    painterController.setNoteScale(0.25);
    painterController.clickScale = 1.5;
    painterController.splashScale = 0.35;
    widget.controller._painterController = painterController;
    _painter = _Painter(controller: painterController);
    widget.onLoad?.call(
      musicTotalTime ?? estTotalTime,
      offset,
      formatVersion,
      phasetida.getBufferSize().toInt(),
    );
    _reDrawTicker = createTicker((_) {
      (_canvasKey.currentContext?.findRenderObject() as RenderBox?)
          ?.markNeedsPaint();
      widget.controller.logTime.value = painterController.logTime ?? 0;
      widget.controller.logCombo.value = painterController.logCombo ?? 0;
      widget.controller.logMaxCombo.value = painterController.logMaxCombo ?? 0;
      widget.controller.logScore.value = painterController.logScore ?? 0;
      widget.controller.logAccurate.value = painterController.logAccurate ?? 0;
      widget.controller.logBufferUsage.value =
          painterController.logBufferUsage ?? 0;
    })..start();
    painterController.setupTime();
    widget.controller.setSpeed(1.0);
    widget.controller.setPaused(false);
    this.painterController = painterController;
    phasetida.resetNoteState(beforeTimeInSecond: 0);
    setState(() {
      widget.controller.isLoading.value = false;
    });
  }

  void _playSound(AudioSource? sound, int? count) {
    final countN = count ?? 0;
    if (countN > 0 && sound != null) {
      for (int i = 0; i < countN; i++) {
        SoLoud.instance.play(sound);
      }
    }
  }

  Future<ui.Image> _loadImage(String assetsPath) async {
    final data = await rootBundle.load(
      "packages/phasetida_flutter/assets/$assetsPath",
    );
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isLoading.value) {
      return SizedBox.shrink();
    }
    return RepaintBoundary(
      child: Listener(
        onPointerDown: (e) {
          if (painterController?._auto != false) {
            return;
          }
          final position = _painter?.viewport.unProject(
            e.localPosition.dx,
            e.localPosition.dy,
          );
          if (position == null) return;
          final (x, y) = position;
          int index = inputContainer.touchDown(e.pointer);
          if (index == -1) {
            return;
          }
          phasetida.touchAction(state: 0, id: index, x: x, y: y);
        },
        onPointerMove: (e) {
          if (painterController?._auto != false) {
            return;
          }
          final position = _painter?.viewport.unProject(
            e.localPosition.dx,
            e.localPosition.dy,
          );
          if (position == null) return;
          final (x, y) = position;
          int index = inputContainer.touchMove(e.pointer);
          if (index == -1) {
            return;
          }
          phasetida.touchAction(state: 1, id: index, x: x, y: y);
        },
        onPointerCancel: (e) {
          if (painterController?._auto != false) {
            return;
          }
          int index = inputContainer.touchUp(e.pointer);
          if (index == -1) {
            return;
          }
          phasetida.touchAction(state: 2, id: index, x: 0, y: 0);
        },
        onPointerUp: (e) {
          if (painterController?._auto != false) {
            return;
          }
          int index = inputContainer.touchUp(e.pointer);
          if (index == -1) {
            return;
          }
          phasetida.touchAction(state: 2, id: index, x: 0, y: 0);
        },
        child: CustomPaint(
          key: _canvasKey,
          painter: _painter,
          size: Size.infinite,
        ),
      ),
    );
  }

  void _disposeSound(AudioSource? source) {
    if (source != null) {
      try {
        SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _reDrawTicker?.dispose();
    musicTimeSub?.cancel();
    musicSpeedSub?.cancel();
    final songHandle = this.songHandle;
    if (songHandle != null) {
      try {
        SoLoud.instance.stop(songHandle);
      } catch (_) {}
    }
    _disposeSound(tapSound);
    _disposeSound(dragSound);
    _disposeSound(flickSound);
    _disposeSound(songSource);
    tapImage?.dispose();
    tapHighlightImage?.dispose();
    dragImage?.dispose();
    dragHighlightImage?.dispose();
    flickImage?.dispose();
    flickHighlightImage?.dispose();
    holdHeadImage?.dispose();
    holdHeadHighlightImage?.dispose();
    holdBodyImage?.dispose();
    holdBodyHighlightImage?.dispose();
    holdEndImage?.dispose();
    splashImages?.forEach((it) => it.dispose());
    clickImages?.forEach((it) => it.dispose());
    super.dispose();
  }
}
