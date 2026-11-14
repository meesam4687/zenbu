import 'package:d4rt/d4rt.dart';

/// Casts what an extension assigned to a list-typed bridged property, and unwraps
/// any D4rt [BridgedInstance] to its underlying native object.
List<T>? asBridgedList<T>(Object? value, String property) {
  if (value == null) return null;
  if (value is List) {
    return value
        .map((e) => (e is BridgedInstance ? e.nativeObject : e))
        .cast<T>()
        .toList();
  }
  if (value is Callable) {
    throw ArgumentError(
      '$property expects a list, and was given a method rather than the '
      'result of calling one. A missing () is the usual cause, as in '
      '`$property = something.toList` instead of `$property = '
      'something.toList()`.',
    );
  }
  throw ArgumentError(
    '$property expects a list, and was given ${value.runtimeType}.',
  );
}

/// The map equivalent of [asBridgedList], for the same reason.
Map<K, V>? asBridgedMap<K, V>(Object? value, String property) {
  if (value == null) return null;
  if (value is Map) return value.cast<K, V>();
  if (value is Callable) {
    throw ArgumentError(
      '$property expects a map, and was given a method rather than the result '
      'of calling one. A missing () is the usual cause.',
    );
  }
  throw ArgumentError(
    '$property expects a map, and was given ${value.runtimeType}.',
  );
}
