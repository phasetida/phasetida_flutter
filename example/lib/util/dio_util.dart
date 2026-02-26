import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

extension DioWrapper<T> on Future<Response<T>> {
  TaskEither<DioFailure, Response<T>> asTaskEither() {
    return TaskEither(() async {
      try {
        return Either.right(await this);
      } on DioException catch (e) {
        return Either.left(switch (e.type) {
          DioExceptionType.cancel ||
          DioExceptionType.connectionError ||
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout => NetworkFailure(),
          DioExceptionType.badCertificate => BadCertificateFailure(),
          DioExceptionType.badResponse => BadResponseFailure(e.response),
          _ => UnknownFailure(e.message),
        });
      }
    });
  }
}

sealed class DioFailure {}

class NetworkFailure extends DioFailure {}

class BadCertificateFailure extends DioFailure {}

class BadResponseFailure extends DioFailure {
  final Response<dynamic>? response;

  BadResponseFailure(this.response);
}

class UnknownFailure extends DioFailure {
  final String? message;

  UnknownFailure(this.message);
}
