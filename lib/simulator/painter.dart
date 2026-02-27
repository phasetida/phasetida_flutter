part of 'simulator.dart';

class PainterController {
  double? logTime;
  int? logCombo;
  int? logMaxCombo;
  double? logScore;
  double? logAccurate;
  int? logBufferUsage;

  double _startTime = 0;
  double _lastTime = 0;
  double _lastChangeSpeedTime = 0;
  double _speed = 1.0;
  double _lastSpeed = 1.0;

  double globalScale = 1.0;
  double _noteScale = 1.0;
  double clickScale = 1.0;
  double splashScale = 1.0;

  bool _paused = false;
  bool _auto = true;
  bool _showHighlight = true;

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
  final double offset;

  void Function(int, int, int) soundTick;

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
    required this.offset,
    required this.soundTick,
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
    phasetida.resetTouchState();
  }

  void setPaused(bool paused) {
    if (!_paused && paused) {
      _lastSpeed = _speed;
      setSpeed(0.00000001);
    } else if (_paused && !paused) {
      setSpeed(_lastSpeed);
    }
    _paused = paused;
  }
}

class _Painter extends CustomPainter {
  final _Viewport viewport = _Viewport(1920.0, 1080.0);

  late final ui.Paint _linePainter;
  late final ui.Paint _backgroundPainter;
  late final ui.Paint _notePainter;
  late final ui.Paint _perfectPaint;
  late final ui.Paint _goodPaint;
  late final ui.Paint _clickPaint;

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
    _clickPaint = ui.Paint();
    _clickPaint.color = Color.fromARGB(128, 255, 255, 255);
    _clickPaint.style = PaintingStyle.stroke;
    _clickPaint.strokeWidth = 5;
  }

  @override
  void paint(Canvas canvas, Size size) {
    viewport.update(size.width, size.height);
    final now = DateTime.timestamp().millisecondsSinceEpoch / 1000.0;
    final time =
        (controller._lastChangeSpeedTime +
            (now - controller._startTime) * controller._speed) -
        controller.offset;
    final deltaTime = max(time - controller._lastTime, 0.0);
    final bufferWrapper = phasetida.tickLines(
      timeInSecond: time,
      deltaTimeInSecond: deltaTime,
      auto: controller._auto,
    );
    controller._lastTime = time;
    final (pw, ph) = viewport.project(1920.0, 1080.0);

    canvas.drawRect(Rect.fromLTWH(0, 0, pw, ph), _backgroundPainter);
    canvas.clipRect(Rect.fromLTWH(0, 0, pw, ph));
    final reader = ByteDataReader(endian: Endian.little);
    _linePainter.strokeWidth = viewport.projectSize(10.0);
    reader.add(bufferWrapper.inner);

    final noteScale = viewport.projectSize(
      controller.globalScale * controller._noteScale,
    );
    final clickScale = viewport.projectSize(
      controller.clickScale * controller.globalScale,
    );
    final splashScale = viewport.projectSize(
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
            final (px1, py1) = viewport.project(x1, y1);
            final (px2, py2) = viewport.project(x2, y2);
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
            final isHighlight = highlight != 0 && controller._showHighlight;
            final (px, py) = viewport.project(x, y);
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
                : viewport.projectSize(height) / noteImage.height;
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
            final (px, py) = viewport.project(x, y);
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
            final x = reader.readFloat32();
            final y = reader.readFloat32();
            final (px, py) = viewport.project(x, y);
            canvas.drawCircle(Offset(px, py), 75, _clickPaint);
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
            final (px, py) = viewport.project(x, y);
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
            controller.soundTick(tapSound, dragSound, flickSound);
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
