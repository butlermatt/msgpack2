part of msgpack;

Uint8Encoder _uInt8Packer;

/// This is a convenience function to pack a value to MsgPack Uint8List. It will
/// handle creating the serializer, initializing the state and returning the
/// properly allocated list. It will reuse an existing instance of the
/// serializer if one exists in order to limit memory usage.
Uint8List serialize(dynamic value) {
  if (_uInt8Packer == null) {
    _uInt8Packer = Uint8Encoder();
  }

  _uInt8Packer.encode(value);
  return _uInt8Packer.done();
}

@deprecated
Uint8List pack(dynamic value) {
  return serialize(value);
}

/// This class manages backing buffers and provides methods to pack data in
/// the contents.
class Uint8Encoder {
  List<Uint8List> _buffers = <Uint8List>[];
  int _curBufId = 0;

  Uint8List _list;
  Uint8List get list => _list;
  ByteData _bd;
  ByteData get byteData => _bd;
  int _offset = 0;
  int _cachedBytes = 0;
  int _bufferSize = defaultBufferSize;

  /// This creates a new instance of the serializer and optionally initializes
  /// the backing Uint8List.
  ///
  /// The instance may create additional buffers of the same size as the
  /// initializing list if the data exceeds the limit of the provided list.
  Uint8Encoder([this._list]) {
    if (_list == null) {
      _list = Uint8List(_bufferSize);
    } else {
      _bufferSize = _list.lengthInBytes;
    }
    _bd = ByteData.view(_list.buffer);
  }

  /// This method will attempt to detect the appropriate method to pack the
  /// supplied [value].
  ///
  /// Throws an [ArgumentError] if it cannot determine the correct method to
  /// pack the value.
  void encode(dynamic value) {
    if (value == null) return encodeNull();
    if (value is bool) return encodeBool(value);
    if (value is int) return encodeInt(value);
    if (value is Float) return encodeFloat(value);
    if (value is double) return encodeFloat(value);
    if (value is String) return encodeString(value);
    if (value is ByteData) return encodeBinary(value);
    if (value is List) return encodeArray(value);
    if (value is Map) return encodeMap(value);
    if (value is ExtensionFormat) return encodeExtension(value);
    if (value is DateTime) {
      var dateExt = ExtTimeStamp(value);
      return encodeExtension(dateExt);
    }

    throw ArgumentError('Cannot pack type: ${value.runtimeType}');
  }

  /// This method will iterate through the values in an [Iterable] and pack
  /// each one in turn. The Iterable itself will not be packed (eg, it will
  /// not pack it as an Array).
  /// This calls [encode] on each value.
  void encodeAll(Iterable values) {
    for (var v in values) {
      encode(v);
    }
  }

  /// This method will pack a null/nil value.
  void encodeNull() {
    _checkBuffer();
    _list[_offset++] = 0xc0;
  }

  /// This method will pack the [bool] value `true` or `false`
  void encodeBool(bool value) {
    _checkBuffer();
    int data = 0xc2; // false
    if (value) data += 1; // true
    _list[_offset++] = data;
  }

  /// This method will pack both the appropriate [IntType] value and the value
  /// itself, as well as increment the buffer offset appropriately.
  void encodeInt(int value) {
    var size = value.bitLength;
    IntType type;

    if (value >= 0) {
      if (size < 8) {
        _checkBuffer();
        _list[_offset++] = value;
        return;
      }

      if (size == 8) {
        type = IntType.Uint8;
      } else if (size <= 16) {
        type = IntType.Uint16;
      } else if (size <= 32) {
        type = IntType.Uint32;
      } else {
        type = IntType.Uint64;
      }

      _list[_offset++] = type.value;
      encodeIntType(type, value);
      return; // Done positive checks
    }

    // negative bits length needs to add one
    // https://api.dartlang.org/dart-core/int/bitLength.html
    size += 1;
    if (size <= 6) {
      _checkBuffer();
      _bd.setInt8(_offset++, value);
      return;
    } else if (size <= 8) {
      type = IntType.Int8;
    } else if (size <= 16) {
      type = IntType.Int16;
    } else if (size <= 32) {
      type = IntType.Int32;
    } else {
      type = IntType.Int64;
    }

    _list[_offset++] = type.value;
    encodeIntType(type, value);
  }

  /// This method will pack the specified integer value __without__ the msgPack
  /// [IntType] value. This will only pack the specified [value]
  void encodeIntType(IntType type, int value) {
    _checkBuffer();
    var rem = _list.lengthInBytes - _offset;

    // Shortcut if there's definitely room
    if (rem >= 8) {
      _packFullInt(type, value);
      return;
    }

    // May still fit, check if there's room.
    var sizeNeed = 0;
    switch (type) {
      case IntType.Uint8:
      case IntType.Int8:
        sizeNeed = 1;
        break;
      case IntType.Uint16:
      case IntType.Int16:
        sizeNeed = 2;
        break;
      case IntType.Uint32:
      case IntType.Int32:
        sizeNeed = 4;
        break;
      case IntType.Uint64:
      case IntType.Int64:
        sizeNeed = 8;
        break;
    }

    if (rem >= sizeNeed) {
      _packFullInt(type, value);
      return;
    }

    // Doesn't fit, break it up and add pieces;
    var pieces = Uint8List(sizeNeed);
    var bd = ByteData.view(pieces.buffer);
    switch (type) {
      case IntType.Uint16:
        bd.setUint16(0, value);
        break;
      case IntType.Int16:
        bd.setInt16(0, value);
        break;
      case IntType.Uint32:
        bd.setUint32(0, value);
        break;
      case IntType.Int32:
        bd.setInt32(0, value);
        break;
      case IntType.Uint64:
        bd.setUint64(0, value);
        break;
      case IntType.Int64:
        bd.setInt64(0, value);
        break;
    }

    _packPartial(pieces);
  }

  void _packFullInt(IntType type, int value) {
    switch (type) {
      case IntType.Uint8:
        _list[_offset++] = value;
        return;
      case IntType.Uint16:
        _writeBits(_list, value, 16, _offset);
        _offset += 2;
        return;
      case IntType.Uint32:
        _writeBits(_list, value, 32, _offset);
        _offset += 4;
        return;
      case IntType.Uint64:
        _writeBits(_list, value, 64, _offset);
        _offset += 8;
        return;
      case IntType.Int8:
        _list[_offset++] = value + 0x100;
        return;
      case IntType.Int16:
        value += 0x10000;
        _writeBits(_list, value, 16, _offset);
        _offset += 2;
        return;
      case IntType.Int32:
        value += 0x100000000;
        _writeBits(_list, value, 32, _offset);
        _offset += 4;
        return;
      case IntType.Int64:
        _bd.setInt64(_offset, value);
        _offset += 8;
        return;
    }
  }

  /// This method will pack both the appropriate [FloatType] value and the value
  /// itself, as well as increment the buffer offset appropriately.
  /// [value] must be either a [double] or a [Float]
  void encodeFloat(dynamic value) {
    FloatType type;
    double val;
    if (value is Float) {
      type = FloatType.Float32;
      val = value.value;
    } else if (value is double) {
      type = FloatType.Float64;
      val = value;
    } else {
      throw TypeError();
    }
    _checkBuffer();
    _list[_offset++] = type.value;
    encodeFloatType(type, val);
  }

  /// This method will pack the specified [double] value __without__ the msgPack
  /// [FloatType] value. This will only pack the specified [value]
  void encodeFloatType(FloatType type, double value) {
    var rem = _list.lengthInBytes - _offset;

    if (rem >= 4 && type == FloatType.Float32) {
      _bd.setFloat32(_offset, value);
      _offset += 4;
      return;
    } else if (rem >= 8 && type == FloatType.Float64) {
      _bd.setFloat64(_offset, value);
      _offset += 8;
      return;
    }

    Uint8List pieces;
    if (type == FloatType.Float32) {
      pieces = Uint8List(4);
      var bd = ByteData.view(pieces.buffer);
      bd.setFloat32(_offset, value);
      _packPartial(pieces);
      return;
    }

    pieces = Uint8List(8);
    var bd = ByteData.view(pieces.buffer);
    bd.setFloat64(_offset, value);
    _packPartial(pieces);
  }

  /// This method will pack both the appropriate [StringType] value, the size
  /// (up to 32 bit unsigned length) and the [String] itself, as well as
  /// increment the buffer offset appropriately.
  void encodeString(String value) {
    Uint8List encoded;
    if (StringCache.has(value)) {
      encoded = StringCache.get(value);
    } else {
      encoded = _toUTF8(value);
    }

    var size = encoded.lengthInBytes;
    Uint8List pieces;
    if (size < 32) {
      pieces = Uint8List(size + 1);
      pieces[0] = StringType.FixStr.value | size;
      pieces.setRange(1, size + 1, encoded);
    } else if (size <= 0xff) {
      // 255: 1 byte size
      pieces = Uint8List(size + 2);
      pieces[0] = StringType.Str8.value;
      pieces[1] = size;
      pieces.setRange(2, size + 2, encoded);
    } else if (size <= 0xffff) {
      pieces = Uint8List(size + 3);
      pieces[0] = StringType.Str16.value;
      _writeBits(pieces, size, 16, 1);
      pieces.setRange(3, size + 3, encoded);
    } else if (size > 0xffffffff) {
      throw ArgumentError('String cannot have a length longer than an Uint32');
    } else {
      pieces = Uint8List(size + 5);
      pieces[0] = StringType.Str32.value;
      _writeBits(pieces, size, 32, 1);
      pieces.setRange(5, size + 5, encoded);
    }

    _packPartial(pieces);
  }

  /// This method will pack both the appropriate [BinaryType] value, the size
  /// (up to 32 bit unsigned length) and the binary data itself, as well as
  /// increment the buffer offset appropriately.
  void encodeBinary(ByteData data) {
    var len = data.lengthInBytes;

    Uint8List pieces;
    if (len <= 0xff) {
      // 255 - one byte
      pieces = Uint8List(len + 2);
      pieces[0] = BinaryType.Bin8.value;
      pieces[1] = len;
      pieces.setRange(
          2, len + 2, data.buffer.asUint8List(data.offsetInBytes, len));
    } else if (len <= 0xffff) {
      // 65535 or two bytes
      pieces = Uint8List(len + 3);
      pieces[0] = BinaryType.Bin16.value;
      _writeBits(pieces, len, 16, 1);
      pieces.setRange(
          3, len + 3, data.buffer.asUint8List(data.offsetInBytes, len));
    } else if (len > 0xffffffff) {
      throw ArgumentError('Binary cannot have a length longer than and Uint32');
    } else {
      pieces = Uint8List(len + 5);
      pieces[0] = BinaryType.Bin32.value;
      _writeBits(pieces, len, 32, 1);
      pieces.setRange(
          5, len + 5, data.buffer.asUint8List(data.offsetInBytes, len));
    }

    _packPartial(pieces);
  }

  /// This method will pack both the appropriate [ArrayType] value, the size
  /// (up to 32 bit unsigned length) and the [List] contents itself, as well as
  /// increment the buffer offset appropriately.
  ///
  /// List contents will also be packed with their respective [MsgType] values.
  /// `size` will be the number of items in the list, rather than the byteLength
  /// those elements will consume.
  void encodeArray(List value) {
    var len = value.length;

    if (len <= 15) {
      _checkBuffer();
      _bd.setUint8(_offset++, len | ArrayType.FixArray.value);
    } else if (len <= 0xffff) {
      var rem = _list.lengthInBytes - _offset;
      if (rem >= 3) {
        _list[_offset++] = ArrayType.Array16.value;
        _writeBits(_list, len, 16, _offset);
        _offset += 2;
      } else {
        var pieces = Uint8List(3);
        pieces[0] = ArrayType.Array16.value;
        _writeBits(pieces, len, 16, 1);
        _packPartial(pieces);
      }
    } else if (len > 0xffffffff) {
      throw ArgumentError('Array cannot contain more than Uint32 elements');
    } else {
      var rem = _list.lengthInBytes - _offset;
      if (rem >= 5) {
        _list[_offset++] = ArrayType.Array32.value;
        _writeBits(_list, len, 32, _offset);
        _offset += 4;
      } else {
        var pieces = Uint8List(5);
        pieces[0] = ArrayType.Array32.value;
        _writeBits(pieces, len, 32, 1);
        _packPartial(pieces);
      }
    }

    for (var el in value) {
      encode(el);
    }
  }

  /// This method will pack both the appropriate [MapType] value, the size
  /// (up to 32 bit unsigned length) and the [Map] contents itself, as well as
  /// increment the buffer offset appropriately.
  ///
  /// Map contents (key and values) will also be packed with their respective
  /// [MsgType] values.
  /// `size` will be the number of key/value pairs in the Map, rather than the
  /// byteLength those elements will consume.
  void encodeMap(Map value) {
    var len = value.length;

    var rem = _list.lengthInBytes - _offset;
    if (len <= 15) {
      _checkBuffer();
      _list[_offset++] = len | MapType.FixMap.value;
    } else if (len <= 0xffff) {
      if (rem >= 3) {
        _checkBuffer();
        _list[_offset++] = MapType.Map16.value;
        _writeBits(_list, len, 16, _offset);
        _offset += 2;
      } else {
        var pieces = Uint8List(3);
        pieces[0] = MapType.Map16.value;
        _writeBits(pieces, len, 16, 1);
        _packPartial(pieces);
      }
    } else if (len > 0xffffffff) {
      throw ArgumentError('Map cannot contain more than Uint32 elements');
    } else {
      if (rem >= 5) {
        _list[_offset++] = MapType.Map32.value;
        _writeBits(_list, len, 32, _offset);
        _offset += 4;
      } else {
        var pieces = Uint8List(5);
        pieces[0] = MapType.Map32.value;
        _writeBits(pieces, len, 32, 1);
        _packPartial(pieces);
      }
    }

    value.forEach((key, val) {
      encode(key);
      encode(val);
    });
  }

  /// This method accepts a value of a sub-type of [ExtensionFormat]. It will
  /// create a new Uint8Packer and pass it to the [ExtensionFormat.encode] method.
  /// Once completed it will call [done] to retrieve the packed extension
  /// data. It will then pack the appropriate [ExtType] value, size and the
  /// packed data.
  ///
  /// If there is no registered extension for the [value.typeId] then it will
  /// throw a StateError.
  void encodeExtension(ExtensionFormat value) {
    if (!_extCache.containsKey(value.typeId)) {
      throw StateError('No registered builder for type id: ${value.typeId}');
    }
    var packer = Uint8Encoder(Uint8List(256));
    value.encode(packer);

    var data = packer.done();
    _checkBuffer();
    ExtType type;

    var len = data.lengthInBytes;
    if (len == 1) {
      type = ExtType.FixExt1;
    } else if (len == 2) {
      type == ExtType.FixExt2;
    } else if (len == 4) {
      type = ExtType.FixExt4;
    } else if (len == 8) {
      type = ExtType.FixExt8;
    } else if (len == 16) {
      type = ExtType.FixExt16;
    }

    if (type != null) {
      _list[_offset++] = type.value;
      _checkBuffer();
      _bd.setInt8(_offset++, value.typeId);
      _packPartial(data);
      return;
    }

    var rem = _list.lengthInBytes - _offset;
    if (data.lengthInBytes <= 0xff) {
      _list[_offset++] = ExtType.Ext8.value;
      _checkBuffer();
      _list[_offset++] = data.lengthInBytes;
    } else if (data.lengthInBytes <= 0xffff) {
      _list[_offset++] = ExtType.Ext16.value;
      if (rem < 3) {
        var pieces = Uint8List(2);
        _writeBits(pieces, data.lengthInBytes, 16, 0);
        _packPartial(pieces);
      } else {
        _writeBits(_list, data.lengthInBytes, 16, _offset);
      }
      _offset += 2;
    } else if (data.lengthInBytes <= 0xffffffff) {
      _list[_offset++] = ExtType.Ext32.value;
      if (rem < 5) {
        var pieces = Uint8List(4);
        _writeBits(pieces, data.lengthInBytes, 32, 0);
        _packPartial(pieces);
      } else {
        _writeBits(_list, data.lengthInBytes, 32, _offset);
      }
    }

    _checkBuffer();
    _bd.setInt8(_offset++, value.typeId);
    _packPartial(data);
  }

  void _packPartial(Uint8List pieces) {
    var ind = 0;
    while (ind < pieces.lengthInBytes) {
      var spaceRem = _list.lengthInBytes - _offset;
      var piecesRem = pieces.lengthInBytes - ind;
      var stop = piecesRem > spaceRem ? spaceRem : piecesRem;

      for (var i = 0; i < stop; i++) {
        _bd.setUint8(_offset++, pieces[ind++]);
      }

      _checkBuffer();
    }
  }

  static void _writeBits(Uint8List list, int value, int bits, int ind) {
    for (bits -= 8; bits > 0; bits -= 8) {
      list[ind++] = (value >> bits) & 0xff;
    }

    list[ind++] = value & 0xff;
  }

  /// This method will return the data that has been packed in the buffers,
  /// and reset them. If the optional named parameter [reuse] is true, it will
  /// leave the existing buffers and reset positions rather than allocating
  /// new buffers and garbage collecting the old buffers.
  Uint8List done({bool reuse = false}) {
    var out = _collectData();

    if (!reuse) {
      _buffers = List<Uint8List>();
      _list = Uint8List(_bufferSize);
    }

    _cachedBytes = 0;
    _curBufId = 0;
    _offset = 0;
    _bd = ByteData.view(_list.buffer, 0);

    return out;
  }

  Uint8List _collectData() {
    if (_curBufId == 0) {
      return _bd.buffer.asUint8List(0, _offset);
    }

    var out = Uint8List(_cachedBytes + _offset);
    var ind = 0;
    for (var i = 0; i < _curBufId; i++) {
      var b = _buffers[i];
      out.setRange(ind, ind + b.lengthInBytes, b);
      ind += b.lengthInBytes;
    }

    if (_offset > 0) {
      out.setRange(ind, ind + _offset, _list);
    }
    return out;
  }

  void _checkBuffer() {
    if (_offset < _list.lengthInBytes) return;

    if (_curBufId == _buffers.length) {
      _buffers.add(_list);
    } else {
      _buffers[_curBufId] = _list;
    }

    _cachedBytes += _list.lengthInBytes;

    _list = Uint8List(_bufferSize);
    _bd = ByteData.view(_list.buffer);
    _curBufId += 1;
    _offset = 0;
  }
}
