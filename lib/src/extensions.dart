part of msgpack;

abstract class ExtensionFormat {
  /// This property is a unique type ID from 0 to 127.
  int get typeId;

  /// This method is called when the [ExtensionFormat] sub-type is added to
  /// the Packer. A new [Uint8Encoder] is created and passed to this method
  /// which can be used to pack values, either as simple types or full MsgPack
  /// values, including their type encoding.
  ///
  /// Do not pack the ExtensionFormat value or size values, these are handled
  /// by the Uint8Packer that receives the ExtensionFormat sub-type. (See:
  /// [Uint8Encoder.encodeExtension]
  void encode(Uint8Encoder encoder);

  /// This method is called when the [Uint8Decoder] reads an Extension Format
  /// message with a registered [typeId] for the [ExtensionFormat] sub-type.
  /// A new Uint8Unpacker with only the bytes of this message. The unpacker
  /// can be used to easily unpack the values as added by the Packer in [encode].
  dynamic decode(Uint8Decoder decoder);
}

Map<int, ExtensionFormat> _extCache = <int, ExtensionFormat>{
  -1: ExtTimeStamp(null)
};

/// Register a type for the ExtensionFormat. Type [T] must implement the
/// [ExtensionFormat] class
///
/// Throws an ArguementError if `obj.typeId` is < 0 or > 127.
/// Throws a StateError if `obj.typeId` is already registered.
void registerExtension<T extends ExtensionFormat>(T obj) {
  if (obj.typeId < 0 || obj.typeId > 127) {
    throw ArgumentError.value(
        obj.typeId, "typeId", "typeId must be between 0 and 127");
  }

  if (_extCache.containsKey(obj.typeId)) {
    throw StateError('Type ID: ${obj.typeId} is already registered.');
  }
  _extCache[obj.typeId] = obj;
}

/// This class implements the Timestamp extension type as defined in the
/// MsgPack spec. Due to the precision implemented in the Dart language, we
/// only encode using the 64 or 96 bit encodings (and not the 32 bit). However
/// we can decode from all formats specified in the spec.
class ExtTimeStamp implements ExtensionFormat {
  final DateTime time;
  final int typeId = -1;

  /// Constructor takes the [DateTime] to be packaged, this can be then passed
  /// to the [serialize] function, [Uint8Encoder.encode] or
  /// [Uint8Encoder.encodeExtension] methods to encode the Timestamp in MsgPack.
  const ExtTimeStamp(this.time);

  void encode(Uint8Encoder encoder) {
    // We always pack Timestamps to 64 or 96-bit timestamps.
    // Can't directly get seconds, so fake it till you make it.
    var sec = time.millisecondsSinceEpoch ~/ 1000;
    // Use Microseconds for better precision.
    // Max nsec size is 999,999,999
    // Start with the modulus rather than convert to nano to limit chance
    // of an overflow.
    var nsec = time.microsecondsSinceEpoch % 1000000;
    nsec *= 1000; // Convert 999,999 microseconds to Nanoseconds.
    if (sec < 0) {
      sec += nsec ~/ (1000 * 1000); // remove seconds represented by nanoseconds
    } else {
      sec -= nsec ~/ (1000 * 1000); // remove seconds represented by nanoseconds
    }
    if (sec >= 0 && sec.bitLength <= 34) {
      var data = (nsec << 34) | sec;
      encoder.encodeIntType(IntType.Uint64, data);
      return;
    }

    encoder.encodeIntType(IntType.Uint32, nsec);
    encoder.encodeIntType(IntType.Int64, sec);
  }

  DateTime decode(Uint8Decoder decoder) {
    int sec;
    int nsec;
    if (decoder.list.lengthInBytes == 4) {
      sec = decoder.decodeInt(IntType.Uint32);
      return DateTime.fromMillisecondsSinceEpoch(sec * 1000);
    }

    if (decoder.list.lengthInBytes == 8) {
      var data = decoder.decodeInt(IntType.Uint64);
      nsec = data >> 34;
      sec = data & 0x3ffffffff;
    } else {
      // 96 bit signed
      nsec = decoder.decodeInt(IntType.Uint32);
      sec = decoder.decodeInt(IntType.Int64);
    }

    nsec ~/= 1000 * 1000;
    if (sec < 0) nsec = -nsec;
    var ms = (sec + nsec) * 1000 + nsec;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
