import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:buffer/buffer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:phasetida_flutter/src/rust/api/phasetida.dart' as phasetida;

class PhigrosSimulatorRenderWidget extends StatefulWidget {
  final PhigrosSimulatorRenderController controller;
  final void Function(double totalTime, int bufferSize)? onLoad;
  final String levelJson;

  const PhigrosSimulatorRenderWidget({
    super.key,
    required this.controller,
    required this.levelJson,
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
  ValueNotifier<int> logTapSound = ValueNotifier(0);
  ValueNotifier<int> logDragSound = ValueNotifier(0);
  ValueNotifier<int> logFlickSound = ValueNotifier(0);
  ValueNotifier<int> logBufferUsage = ValueNotifier(0);
  ValueNotifier<bool> isLoading = ValueNotifier(true);
  ValueNotifier<String?> loadError = ValueNotifier(null);

  bool _enableSound = true;

  void setTime(double time) {
    _painterController?.setTime(time);
  }

  void setSpeed(double speed) {
    _painterController?.setSpeed(speed);
  }

  void setAutoPlay(bool auto) {
    //TODO
  }

  void setHighlight(bool highlight) {
    _painterController?.showHighlight = highlight;
  }

  void setEnableSound(bool enableSound) {
    _enableSound = enableSound;
  }
}

class _PhigrosSimulatorRenderWidgetState
    extends State<PhigrosSimulatorRenderWidget>
    with SingleTickerProviderStateMixin {
  final _canvasKey = GlobalKey();

  double totalTime = -1.0;

  _Painter? _painter;
  PainterController? painterController;

  ui.Image? _tapImage;
  ui.Image? _tapHighlightImage;
  ui.Image? _dragImage;
  ui.Image? _dragHighlightImage;
  ui.Image? _flickImage;
  ui.Image? _flickHighlightImage;
  ui.Image? _holdHeadImage;
  ui.Image? _holdHeadHighlightImage;
  ui.Image? _holdBodyImage;
  ui.Image? _holdBodyHighlightImage;
  ui.Image? _holdEndImage;
  List<ui.Image>? _splashImages;
  List<ui.Image>? _clickImages;
  AudioSource? _tapSound;
  AudioSource? _dragSound;
  AudioSource? _flickSound;

  Ticker? _reDrawTicker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    phasetida.clearStates();
    try {
      final length = phasetida.loadLevel(json: widget.levelJson);
      totalTime = length;
    } catch (e) {
      widget.controller.isLoading.value = false;
      widget.controller.loadError.value = "failed to load level: $e";
      return;
    }
    try {
      _tapImage = await _loadImage("notes/tap.png");
      _tapHighlightImage = await _loadImage("notes/tap_hl.png");
      _dragImage = await _loadImage("notes/drag.png");
      _dragHighlightImage = await _loadImage("notes/drag_hl.png");
      _flickImage = await _loadImage("notes/flick.png");
      _flickHighlightImage = await _loadImage("notes/flick_hl.png");
      _holdHeadImage = await _loadImage("notes/hold_head.png");
      _holdHeadHighlightImage = await _loadImage("notes/hold_head_hl.png");
      _holdBodyImage = await _loadImage("notes/hold_body.png");
      _holdBodyHighlightImage = await _loadImage("notes/hold_body_hl.png");
      _holdEndImage = await _loadImage("notes/hold_end.png");
      _splashImages = await Future.wait(
        List.generate(30, (i) async => _loadImage("splash/splash$i.png")),
      );
      _clickImages = await Future.wait(
        List.generate(30, (i) async => _loadImage("clicks/click$i.png")),
      );
    } catch (e) {
      widget.controller.isLoading.value = false;
      widget.controller.loadError.value = "failed to load image: $e";
      return;
    }
    try {
      _tapSound = await SoLoud.instance.loadAsset(
        "packages/phasetida_flutter/assets/sound/hitSong0.wav",
      );
      _dragSound = await SoLoud.instance.loadAsset(
        "packages/phasetida_flutter/assets/sound/hitSong1.wav",
      );
      _flickSound = await SoLoud.instance.loadAsset(
        "packages/phasetida_flutter/assets/sound/hitSong2.wav",
      );
    } catch (e) {
      widget.controller.isLoading.value = false;
      widget.controller.loadError.value = "failed to load sound: $e";
      return;
    }
    final painterController = PainterController(
      tapImage: _tapImage!,
      tapHighlightImage: _tapHighlightImage!,
      dragImage: _dragImage!,
      dragHighlightImage: _dragHighlightImage!,
      flickImage: _flickImage!,
      flickHighlightImage: _flickHighlightImage!,
      holdHeadImage: _holdHeadImage!,
      holdHeadHighlightImage: _holdHeadHighlightImage!,
      holdBodyImage: _holdBodyImage!,
      holdBodyHighlightImage: _holdBodyHighlightImage!,
      holdEndImage: _holdEndImage!,
      splashImages: _splashImages!,
      clickImages: _clickImages!,
    );
    painterController.setNoteScale(0.25);
    painterController.clickScale = 1.5;
    painterController.splashScale = 0.35;
    widget.controller._painterController = painterController;
    _painter = _Painter(controller: painterController);
    widget.onLoad?.call(totalTime, phasetida.getBufferSize().toInt());
    _reDrawTicker = createTicker((_) {
      (_canvasKey.currentContext?.findRenderObject() as RenderBox?)
          ?.markNeedsPaint();
      widget.controller.logTime.value = painterController.logTime ?? 0;
      widget.controller.logCombo.value = painterController.logCombo ?? 0;
      widget.controller.logMaxCombo.value = painterController.logMaxCombo ?? 0;
      widget.controller.logScore.value = painterController.logScore ?? 0;
      widget.controller.logAccurate.value = painterController.logAccurate ?? 0;
      widget.controller.logTapSound.value = painterController.logTapSound ?? 0;
      widget.controller.logDragSound.value =
          painterController.logDragSound ?? 0;
      widget.controller.logFlickSound.value =
          painterController.logFlickSound ?? 0;
      widget.controller.logBufferUsage.value =
          painterController.logBufferUsage ?? 0;
      if (widget.controller._enableSound) {
        _playSound(_tapSound, painterController.logTapSound);
        _playSound(_dragSound, painterController.logDragSound);
        _playSound(_flickSound, painterController.logFlickSound);
      }
    })..start();
    painterController.setupTime();
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
      child: CustomPaint(
        key: _canvasKey,
        painter: _painter,
        size: Size.infinite,
      ),
    );
  }

  @override
  void dispose() {
    _reDrawTicker?.dispose();
    super.dispose();
  }
}

class _Viewport {
  double worldWidth;
  double worldHeight;
  double scale = 0.0;

  _Viewport(this.worldWidth, this.worldHeight);

  void update(double innerWidth, double innerHeight) {
    scale = min(innerWidth / worldWidth, innerHeight / worldHeight);
  }

  (double, double) project(double worldX, double worldY) =>
      (worldX * scale, worldY * scale);

  (double, double) unProject(double absoluteX, double absoluteY) =>
      (absoluteX / scale, absoluteY / scale);

  double projectSize(double worldSize) => worldSize * scale;

  double unProjectSize(double absoluteSize) => absoluteSize / scale;
}

class PainterController {
  double? logTime;
  int? logCombo;
  int? logMaxCombo;
  double? logScore;
  double? logAccurate;
  int? logTapSound;
  int? logDragSound;
  int? logFlickSound;
  int? logBufferUsage;

  double _startTime = 0;
  double _lastTime = 0;
  double _lastChangeSpeedTime = 0;
  double _speed = 1.0;

  double globalScale = 1.0;
  double _noteScale = 1.0;
  double clickScale = 1.0;
  double splashScale = 1.0;

  bool showHighlight = true;

  final ui.Image tapImage;
  final ui.Image tapHighlightImage;
  final ui.Image dragImage;
  final ui.Image dragHighlightImage;
  final ui.Image flickImage;
  final ui.Image flickHighlightImage;
  final ui.Image holdHeadImage;
  final ui.Image holdHeadHighlightImage;
  final ui.Image holdBodyImage;
  final ui.Image holdBodyHighlightImage;
  final ui.Image holdEndImage;
  final List<ui.Image> splashImages;
  final List<ui.Image> clickImages;

  PainterController({
    required this.tapImage,
    required this.tapHighlightImage,
    required this.dragImage,
    required this.dragHighlightImage,
    required this.flickImage,
    required this.flickHighlightImage,
    required this.holdHeadImage,
    required this.holdHeadHighlightImage,
    required this.holdBodyImage,
    required this.holdBodyHighlightImage,
    required this.holdEndImage,
    required this.splashImages,
    required this.clickImages,
  });

  void setupTime() {
    _startTime = DateTime.timestamp().millisecondsSinceEpoch / 1000.0;
    _lastChangeSpeedTime = 0;
  }

  void setNoteScale(double noteScale) {
    _noteScale = noteScale;
    phasetida.loadImageOffset(
      holdHeadHeight: holdHeadImage.height.toDouble() * _noteScale,
      holdHeadHighlightHeight:
          holdHeadHighlightImage.height.toDouble() * _noteScale,
      holdEndHeight: holdEndImage.height.toDouble() * _noteScale,
      holdEndHighlightHeight: holdEndImage.height.toDouble() * _noteScale,
    );
  }

  void setSpeed(double speed) {
    final now = DateTime.timestamp().millisecondsSinceEpoch / 1000.0;
    _lastChangeSpeedTime += (now - _startTime) * _speed;
    _startTime = now;
    _speed = speed;
  }

  void setTime(double time) {
    final now = DateTime.timestamp().millisecondsSinceEpoch / 1000.0;
    _lastChangeSpeedTime = 0.0;
    _startTime = now - time / _speed;
    _lastTime = 0.0;
    phasetida.resetNoteState(beforeTimeInSecond: time);
  }
}

class _Painter extends CustomPainter {
  final _Viewport _viewport = _Viewport(1920.0, 1080.0);

  late final ui.Paint _linePainter;
  late final ui.Paint _backgroundPainter;
  late final ui.Paint _notePainter;
  late final ui.Paint _perfectPaint;
  late final ui.Paint _goodPaint;

  final PainterController controller;

  _Painter({required this.controller}) {
    _linePainter = ui.Paint();
    _linePainter.color = Color.fromARGB(255, 255, 254, 183);
    _backgroundPainter = ui.Paint();
    _backgroundPainter.style = PaintingStyle.fill;
    _backgroundPainter.color = Color.fromARGB(255, 0, 0, 0);
    _notePainter = ui.Paint();
    _perfectPaint = ui.Paint();
    _perfectPaint.colorFilter = ColorFilter.mode(
      Color.fromARGB(255, 255, 254, 183),
      BlendMode.modulate,
    );
    _goodPaint = ui.Paint();
    _goodPaint.colorFilter = ColorFilter.mode(
      Color.fromARGB(255, 168, 239, 246),
      BlendMode.modulate,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _viewport.update(size.width, size.height);
    final now = DateTime.timestamp().millisecondsSinceEpoch / 1000.0;
    final time =
        (controller._lastChangeSpeedTime +
        (now - controller._startTime) * controller._speed);
    final deltaTime = max(time - controller._lastTime, 0.0);
    final bufferWrapper = phasetida.tickLines(
      timeInSecond: time,
      deltaTimeInSecond: deltaTime,
      auto: true,
    );
    controller._lastTime = time;
    final (pw, ph) = _viewport.project(1920.0, 1080.0);

    canvas.drawRect(Rect.fromLTWH(0, 0, pw, ph), _backgroundPainter);
    canvas.clipRect(Rect.fromLTWH(0, 0, pw, ph));
    final reader = ByteDataReader(endian: Endian.little);
    _linePainter.strokeWidth = _viewport.projectSize(10.0);
    reader.add(bufferWrapper.inner);

    final noteScale = _viewport.projectSize(
      controller.globalScale * controller._noteScale,
    );
    final clickScale = _viewport.projectSize(
      controller.clickScale * controller.globalScale,
    );
    final splashScale = _viewport.projectSize(
      controller.splashScale * controller.globalScale,
    );
    while (true) {
      final rendType = reader.readUint8();
      if (rendType == 0) {
        break;
      }
      switch (rendType) {
        case 1:
          {
            final x1 = reader.readFloat32();
            final y1 = reader.readFloat32();
            final x2 = reader.readFloat32();
            final y2 = reader.readFloat32();
            final alpha = reader.readFloat32();
            final (px1, py1) = _viewport.project(x1, y1);
            final (px2, py2) = _viewport.project(x2, y2);
            _linePainter.color = _linePainter.color.withAlpha(
              (alpha * 255.0).toInt(),
            );
            canvas.drawLine(Offset(px1, py1), Offset(px2, py2), _linePainter);
          }
        case 2:
          {
            final noteType = reader.readUint8();
            final x = reader.readFloat32();
            final y = reader.readFloat32();
            final rotate = reader.readFloat32();
            final height = reader.readFloat32();
            final highlight = reader.readUint8();
            final isHighlight = highlight != 0 && controller.showHighlight;
            final (px, py) = _viewport.project(x, y);
            final noteImage = switch (noteType) {
              1 =>
                isHighlight
                    ? controller.tapHighlightImage
                    : controller.tapImage,
              2 =>
                isHighlight
                    ? controller.dragHighlightImage
                    : controller.dragImage,
              4 =>
                isHighlight
                    ? controller.flickHighlightImage
                    : controller.flickImage,
              5 =>
                isHighlight
                    ? controller.holdHeadHighlightImage
                    : controller.holdHeadImage,
              6 =>
                isHighlight
                    ? controller.holdBodyHighlightImage
                    : controller.holdBodyImage,
              7 => controller.holdEndImage,
              _ => throw Exception("phasetida: unknown noteType: $noteType"),
            };
            final verticalScale = noteType != 6
                ? noteScale
                : _viewport.projectSize(height) / noteImage.height;
            noteImage.draw(
              canvas,
              px,
              py,
              rotate,
              noteScale,
              verticalScale,
              _notePainter,
            );
          }
        case 3:
          {
            final x = reader.readFloat32();
            final y = reader.readFloat32();
            final frame = reader.readUint8();
            final tintType = reader.readUint8();
            final (px, py) = _viewport.project(x, y);
            controller.clickImages[frame].draw(
              canvas,
              px,
              py,
              0,
              clickScale,
              clickScale,
              tintType == 0 ? _perfectPaint : _goodPaint,
            );
          }
        case 4:
          {
            reader.readFloat32();
            reader.readFloat32();
          }
        case 5:
          {
            final combo = reader.readUint32();
            final maxCombo = reader.readUint32();
            final score = reader.readFloat32();
            final accurate = reader.readFloat32();
            controller.logCombo = combo;
            controller.logMaxCombo = maxCombo;
            controller.logScore = score;
            controller.logAccurate = accurate;
          }
        case 6:
          {
            final x = reader.readFloat32();
            final y = reader.readFloat32();
            final frame = reader.readUint8();
            final tintType = reader.readUint8();
            final (px, py) = _viewport.project(x, y);
            controller.splashImages[frame].draw(
              canvas,
              px,
              py,
              0,
              splashScale,
              splashScale,
              tintType == 0 ? _perfectPaint : _goodPaint,
            );
          }
        case 7:
          {
            final tapSound = reader.readUint8();
            final dragSound = reader.readUint8();
            final flickSound = reader.readUint8();
            controller.logTapSound = tapSound;
            controller.logDragSound = dragSound;
            controller.logFlickSound = flickSound;
          }
        default:
          throw Exception(
            "phasetida: unknown rendType: $rendType at ${reader.offsetInBytes}",
          );
      }
      controller.logBufferUsage = reader.offsetInBytes;
      controller.logTime = time;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension on ui.Image {
  void draw(
    Canvas canvas,
    double x,
    double y,
    double rotate,
    double scaleX,
    double scaleY,
    ui.Paint paint,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotate / 360.0 * pi * 2.0);
    canvas.scale(scaleX, scaleY);
    canvas.drawImage(this, Offset(-width / 2.0, -height / 2.0), paint);
    canvas.restore();
  }
}
