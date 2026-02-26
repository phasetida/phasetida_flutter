// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'info_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllInfo _$AllInfoFromJson(Map<String, dynamic> json) => AllInfo(
  (json['songs'] as List<dynamic>)
      .map((e) => Song.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Song _$SongFromJson(Map<String, dynamic> json) => Song(
  json['id'] as String,
  json['name'] as String,
  json['composer'] as String,
  Levels.fromJson(json['levels'] as Map<String, dynamic>),
);

Levels _$LevelsFromJson(Map<String, dynamic> json) => Levels(
  json['EZ'] == null
      ? null
      : Level.fromJson(json['EZ'] as Map<String, dynamic>),
  json['HD'] == null
      ? null
      : Level.fromJson(json['HD'] as Map<String, dynamic>),
  json['IN'] == null
      ? null
      : Level.fromJson(json['IN'] as Map<String, dynamic>),
  json['AT'] == null
      ? null
      : Level.fromJson(json['AT'] as Map<String, dynamic>),
);

Level _$LevelFromJson(Map<String, dynamic> json) => Level(
  json['charter'] as String,
  json['all_combo_num'] as num,
  json['difficulty'] as num,
);
