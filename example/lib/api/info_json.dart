import 'package:json_annotation/json_annotation.dart';

part 'info_json.g.dart';

@JsonSerializable(createToJson: false)
class AllInfo {
  final List<Song> songs;

  AllInfo(this.songs);

  factory AllInfo.fromJson(Map<String, dynamic> json) =>
      _$AllInfoFromJson(json);
}

@JsonSerializable(createToJson: false)
class Song {
  final String id;
  final String name;
  final String composer;
  final Levels levels;

  Song(this.id, this.name, this.composer, this.levels);

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}

@JsonSerializable(createToJson: false)
class Levels {
  @JsonKey(name: "EZ")
  final Level? easy;
  @JsonKey(name: "HD")
  final Level? hard;
  @JsonKey(name: "IN")
  final Level? insane;
  @JsonKey(name: "AT")
  final Level? another;

  Levels(this.easy, this.hard, this.insane, this.another);

  factory Levels.fromJson(Map<String, dynamic> json) => _$LevelsFromJson(json);
}

@JsonSerializable(createToJson: false)
class Level {
  final String charter;
  @JsonKey(name: "all_combo_num")
  final num allComboNum;
  final num difficulty;

  Level(this.charter, this.allComboNum, this.difficulty);

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);
}
