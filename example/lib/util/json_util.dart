import 'package:fpdart/fpdart.dart';

extension JsonUtil on Map<String, dynamic>? {
  Either<JsonFailure, T> fromJson<T>(T Function(Map<String, dynamic>) fromJson) {
    try {
      final x = this;
      if (x == null) {
        return Either.left(JsonFailure("json is null"));
      }
      return Either.right(fromJson(x));
    } catch (e) {
      return Either.left(JsonFailure(e.toString()));
    }
  }
}

class JsonFailure {
  final String message;

  JsonFailure(this.message);
}
