part of msgpack;

class Float {
  final double value;

  Float(this.value);

  @override
  String toString() => value.toString();
}

abstract class MsgType {
  int get value;
}

class IntType implements MsgType {
  final int value;

  static const IntType Uint8 = IntType._(0xcc);
  static const IntType Uint16 = IntType._(0xcd);
  static const IntType Uint32 = IntType._(0xce);
  static const IntType Uint64 = IntType._(0xcf);
  static const IntType Int8 = IntType._(0xd0);
  static const IntType Int16 = IntType._(0xd1);
  static const IntType Int32 = IntType._(0xd2);
  static const IntType Int64 = IntType._(0xd3);

  const IntType._(this.value);

  factory IntType(int value) {
    if (value == Uint8.value) return Uint8;
    if (value == Uint16.value) return Uint16;
    if (value == Uint32.value) return Uint32;
    if (value == Uint64.value) return Uint64;
    if (value == Int8.value) return Int8;
    if (value == Int16.value) return Int16;
    if (value == Int32.value) return Int32;
    if (value == Int64.value) return Int64;
    throw ArgumentError('Invalid IntType: 0x${value.toRadixString(16)}');
  }
}

class FloatType implements MsgType {
  final int value;

  static const FloatType Float32 = FloatType._(0xca);
  static const FloatType Float64 = FloatType._(0xcb);

  const FloatType._(this.value);

  factory FloatType(int value) {
    if (value == Float32.value) return Float32;
    if (value == Float64.value) return Float64;

    throw ArgumentError('Invalid FloatType 0x${value.toRadixString(16)}');
  }
}

class StringType implements MsgType {
  final int value;

  static const StringType FixStr = StringType._(0xa0);
  static const StringType Str8 = StringType._(0xd9);
  static const StringType Str16 = StringType._(0xda);
  static const StringType Str32 = StringType._(0xdb);

  const StringType._(this.value);

  factory StringType(int value) {
    if (value & 0xe0 == 0xa0) return FixStr;
    if (value == Str8.value) return Str8;
    if (value == Str16.value) return Str16;
    if (value == Str32.value) return Str32;
    throw ArgumentError('Invalid StringType 0x${value.toRadixString(16)}');
  }
}

class BinaryType implements MsgType {
  final int value;

  static const BinaryType Bin8 = BinaryType._(0xc4);
  static const BinaryType Bin16 = BinaryType._(0xc5);
  static const BinaryType Bin32 = BinaryType._(0xc6);

  const BinaryType._(this.value);

  factory BinaryType(int value) {
    if (value == Bin8.value) return Bin8;
    if (value == Bin16.value) return Bin16;
    if (value == Bin32.value) return Bin32;

    throw ArgumentError('Invalid BinaryType 0x${value.toRadixString(16)}');
  }
}

class ArrayType implements MsgType {
  final int value;

  static const ArrayType FixArray = ArrayType._(0x90);
  static const ArrayType Array16 = ArrayType._(0xdc);
  static const ArrayType Array32 = ArrayType._(0xdd);

  const ArrayType._(this.value);

  factory ArrayType(int value) {
    if (value & 0xf0 == FixArray.value) return FixArray;
    if (value == Array16.value) return Array16;
    if (value == Array32.value) return Array32;

    throw ArgumentError('Invalid ArrayType 0x${value.toRadixString(16)}');
  }
}

class MapType implements MsgType {
  final int value;

  static const MapType FixMap = MapType._(0x80);
  static const MapType Map16 = MapType._(0xde);
  static const MapType Map32 = MapType._(0xdf);

  const MapType._(this.value);

  factory MapType(int value) {
    if (value & 0xf0 == FixMap.value) return FixMap;
    if (value == Map16.value) return Map16;
    if (value == Map32.value) return Map32;

    throw ArgumentError('Invalid MapType 0x${value.toRadixString(16)}');
  }
}

class ExtType implements MsgType {
  final int value;

  static const ExtType FixExt1 = ExtType._(0xd4);
  static const ExtType FixExt2 = ExtType._(0xd5);
  static const ExtType FixExt4 = ExtType._(0xd6);
  static const ExtType FixExt8 = ExtType._(0xd7);
  static const ExtType FixExt16 = ExtType._(0xd8);
  static const ExtType Ext8 = ExtType._(0xc7);
  static const ExtType Ext16 = ExtType._(0xc8);
  static const ExtType Ext32 = ExtType._(0xc9);

  const ExtType._(this.value);

  factory ExtType(int value) {
    if (value == FixExt1.value) return FixExt1;
    if (value == FixExt2.value) return FixExt2;
    if (value == FixExt4.value) return FixExt4;
    if (value == FixExt8.value) return FixExt8;
    if (value == FixExt16.value) return FixExt16;
    if (value == Ext8.value) return Ext8;
    if (value == Ext16.value) return Ext16;
    if (value == Ext32.value) return Ext32;

    throw ArgumentError('Invalid ExtType 0x${value.toRadixString(16)}');
  }
}
