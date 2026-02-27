import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:phasetida_flutter_example/api/info_json.dart';
import 'package:phasetida_flutter_example/util/dio_util.dart' as dio_util;
import 'package:phasetida_flutter_example/util/json_util.dart' as json_util;

class SomniaApi {
  static SomniaApi? _instance;

  static SomniaApi get instance {
    _instance ??= SomniaApi._();
    return _instance!;
  }

  static const rootUrl = "https://somnia.xtower.site";

  final BaseOptions _options = BaseOptions(
    headers: {HttpHeaders.userAgentHeader: 'nofyso_qwq/0.1'},
  );
  late final Dio _dio = Dio(_options);

  SomniaApi._();

  // 是的，fp在dart这边水土不服的说 TvT
  // 为什么咱不能像rust那样写dart呢
  TaskEither<Either<json_util.JsonFailure, dio_util.DioFailure>, AllInfo>
  getAllInfo() =>
      TaskEither<dynamic, AllInfo>.Do(($) async {
        final response = await $(
          _dio
              .get<Map<String, dynamic>>(
                "$rootUrl/info/all_info.json",
                options: Options(responseType: ResponseType.json),
              )
              .asTaskEither(),
        );
        return await $(response.data.fromJson(AllInfo.fromJson).toTaskEither());
      }).mapLeft((err) {
        return switch (err) {
          dio_util.DioFailure e => Either.right(e),
          json_util.JsonFailure e => Either.left(e),
          _ => throw Exception("UNREACHABLE"),
        };
      });

  TaskEither<dio_util.DioFailure, String> getChart(
    String id,
    String difficulty,
  ) => TaskEither<dio_util.DioFailure, String>.Do(($) async {
    final response = await $(
      _dio
          .get<String>(
            "$rootUrl/chart/$id/$difficulty.json",
            options: Options(responseType: ResponseType.plain),
          )
          .asTaskEither(),
    );
    final data = response.data;
    if (data == null) {
      await $(TaskEither.left(dio_util.NetworkFailure()));
      throw Exception("UNREACHABLE");
    }
    return data;
  });

  TaskEither<dio_util.DioFailure, Uint8List> getSong(String id) =>
      TaskEither<dio_util.DioFailure, Uint8List>.Do(($) async {
        final response = await $(
          _dio
              .get<Uint8List>(
                "$rootUrl/music/${id.substring(0, id.length - 2)}.ogg",
                options: Options(responseType: ResponseType.bytes),
              )
              .asTaskEither(),
        );
        final data = response.data;
        if (data == null) {
          await $(TaskEither.left(dio_util.NetworkFailure()));
          throw Exception("UNREACHABLE");
        }
        return data;
      });
}
