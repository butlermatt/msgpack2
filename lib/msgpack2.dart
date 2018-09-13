library msgpack;

import "dart:convert";
import "dart:typed_data";

part "src/message.dart";
part 'src/types.dart';
part 'src/serialize.dart';
part 'src/deserialize.dart';
part 'src/extensions.dart';

const int defaultBufferSize = const int.fromEnvironment(
    "msgpack.packer.defaultBufferSize",
    defaultValue: 2048);

/// A Cache for Common Strings
class StringCache {
  static Map<String, List<int>> _cache = {};

  static bool has(String str) {
    return _cache.containsKey(str);
  }

  static void store(String string) {
    if (!has(string)) {
      _cache[string] = _toUTF8(string);
    }
  }

  static List<int> get(String string) {
    return _cache[string];
  }

  static void clear() {
    _cache.clear();
  }
}

Uint8List _toUTF8(String str) {
  if (str.codeUnits.any((int c) => c >= 128)) {
    return Uint8List.fromList(const Utf8Codec().encode(str));
  }

  return Uint8List.fromList(str.codeUnits);
}
