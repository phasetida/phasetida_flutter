
part of 'shell.dart';

String _formatTime(double? time) {
  if (time == null) return "-";
  if (time.isNaN || time.isInfinite) return "-";
  final minute = (time / 60.0).floor().toInt();
  final second = (time - (time / 60.0).floor() * 60).toInt();
  final millisecond = ((time - minute * 60.0 - second) * 1000.0)
      .round()
      .toInt();
  return "${"$minute".padLeft(2, "0")}:${"$second".padLeft(2, "0")}.${"$millisecond".padRight(3, "0")}";
}