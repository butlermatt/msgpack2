import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:msgpack2/msgpack2.dart';

var isString = predicate((e) => e is String, 'is a String');
var isInt = predicate((e) => e is int, 'is an int');
var isMap = predicate((e) => e is Map, 'is a Map');
var isList = predicate((e) => e is List, 'is a List');

class TestMessage extends Message {
  int a;
  String b;
  Map c;

  TestMessage(this.a, this.b, this.c);

  static TestMessage fromList(List f) => new TestMessage(f[0], f[1], f[2]);

  List toList() => [a, b, c];
}

class OuterMessage extends Message {
  String a;
  bool b;
  List list;
  TestMessage inner;

  OuterMessage(this.a, this.b, this.list, this.inner);

  static OuterMessage fromList(List f) =>
      new OuterMessage(f[0], f[1], f[2], TestMessage.fromList(f[3]));

  List toList() => [a, b, list, inner];
}

class TestExtension implements ExtensionFormat {
  final int typeId = 1;

  int a;
  String b;
  Map c;

  TestExtension(this.a, this.b, this.c);

  void encode(Uint8Encoder packer) {
    packer.encodeInt(a);
    packer.encodeString(b);
    packer.encodeMap(c);
  }

  TestExtension decode(Uint8Decoder unpacker) {
    var a = unpacker.decode();
    var b = unpacker.decode();
    var c = unpacker.decode();

    return TestExtension(a, b, c);
  }
}

class OuterExtension implements ExtensionFormat {
  final int typeId = 2;

  String a;
  bool b;
  List c;
  TestExtension d;

  OuterExtension(this.a, this.b, this.c, this.d);

  void encode(Uint8Encoder packer) {
    packer.encodeString(a);
    packer.encodeBool(b);
    packer.encodeArray(c);
    packer.encodeExtension(d);
  }

  OuterExtension decode(Uint8Decoder unpacker) {
    var a = unpacker.decode();
    var b = unpacker.decode();
    var c = unpacker.decode();
    var d = unpacker.decode();

    return OuterExtension(a, b, c, d);
  }
}

void main() {
  test("Test multiple buffers", testPartialPacking);
  test("Test Pack null", packNull);

  group("Test Pack Boolean", () {
    test("Pack boolean false", packFalse);
    test("Pack boolean true", packTrue);
  });

  group("Test Pack Ints", () {
    test("Pack Positive FixInt", packPositiveFixInt);
    test("Pack Negative FixInt", packFixedNegative);
    test("Pack Uint8", packUint8);
    test("Pack Uint16", packUint16);
    test("Pack Uint32", packUint32);
    test("Pack Uint64", packUint64);
    test("Pack Int8", packInt8);
    test("Pack Int16", packInt16);
    test("Pack Int32", packInt32);
    test("Pack Int64", packInt64);
  });

  group("Test Pack Floats", () {
    test("Pack Float32", packFloat32);
    test("Pack Float64 (double)", packDouble);
  });

  test("Pack 5-character string", packString5);
  test("Pack 22-character string", packString22);
  test("Pack 256-character string", packString256);
  test("Pack string array", packStringArray);
  test("Pack int-to-string map", packIntToStringMap);
  //test("Pack 3-field message", packMessage);
  //test("Pack nested message", packNestedMessage);

  group("Test Pack Binary", () {
    test("Pack Bin8", packBin8);
    test("Pack Bin16", packBin16);
    test("Pack Bin32", packBin32, skip: true);
    test("Pack Bin with different offset", packBinOffset);
  });

  group("Test Pack Extension Format", () {
    // TODO: More DateTime tests (negative dates, far in future dates)
    // Add custom packing format.
    test("Pack small DateTime", packSmallDateTime);
    test("Pack Past DateTime", packPastDate);
    test("Pack custom extension", packCustomExtension);
    test("Pack nested custom extension", packNestedCustomExtension);
  });

  test("Test Unpack Null", unpackNull);

  group("Test Unpack boolean", () {
    test("Unpack boolean false", unpackFalse);
    test("Unpack boolean true", unpackTrue);
  });

  group("Test Unpack Ints", () {
    test("Unpack Positive FixInt", unpackPositiveFixInt);
    test("Unpack Negative FixInt", unpackNegativeFixInt);
    test("Unpack Uint8", unpackUint8);
    test("Unpack Uint16", unpackUint16);
    test("Unpack Uint32", unpackUint32);
    test("Unpack Uint64", unpackUint64);
    test("Unpack Int8", unpackInt8);
    test("Unpack Int16", unpackInt16);
    test("Unpack Int32", unpackInt32, skip: true);
    test("Unpack Int64", unpackInt64);
  });

  group("Test Unpack Floats", () {
    test("Unpack Float32", unpackFloat32);
    test("Unpack Float64 (double)", unpackDouble);
  });

  test("Unpack 5-character string", unpackString5);
  test("Unpack 22-character string", unpackString22);
  test("Unpack 256-character string", unpackString256);
  test("Unpack string array", unpackStringArray);
  test("Unpack int-to-string map", unpackIntToStringMap);

  group("Test Unpack Extension Format", () {
    // TODO: More DateTime tests (negative dates, far in future dates)
    test("Unpack small date", unpackSmallDateTime);
    test("Unpack past date", unpackPastDate);
    test("Unpack custom extension", unpackCustomExtension);
    test("Unpack nested custom extension", unpackNestedCustomExtension);
  });

  group("Test Large Array and Map", () {
    test("Large Array", largeArray);
    test("Very Large Array", veryLargeArray);
    test("Large Map", largeMap);
    test("Very Large Map", veryLargeMap);
  });
}

void largeArray() {
  final list = List<String>();
  for (int i = 0; i < 16; ++i) {
    list.add("Item $i");
  }

  final serialized = serialize(list);
  List deserialized = deserialize(serialized);
  expect(deserialized, list);
}

void veryLargeArray() {
  final list = List<String>();
  for (int i = 0; i < 65536; ++i) {
    list.add("Item $i");
  }

  final serialized = serialize(list);
  List deserialized = deserialize(serialized);
  expect(deserialized, list);
}

void largeMap() {
  final map = Map<int, String>();
  for (int i = 0; i < 16; ++i) {
    map[i] = "Item $i";
  }
  final serialized = serialize(map);
  Map deserialized = deserialize(serialized);
  expect(deserialized, map);
}

void veryLargeMap() {
  final map = Map<int, String>();
  for (int i = 0; i < 65536; ++i) {
    map[i] = "Item $i";
  }
  final serialized = serialize(map);
  Map deserialized = deserialize(serialized);
  expect(deserialized, map);
}

// Test packing
void testPartialPacking() {
  var packer = Uint8Encoder(Uint8List(2));
  packer.encode(32768);
  var encoded = packer.done();
  expect(encoded, orderedEquals([205, 128, 0]));
}

void packNull() {
  List<int> encoded = serialize(null);
  expect(encoded, orderedEquals([0xc0]));
}

void packFalse() {
  List<int> encoded = serialize(false);
  expect(encoded, orderedEquals([0xc2]));
}

void packTrue() {
  List<int> encoded = serialize(true);
  expect(encoded, orderedEquals([0xc3]));
}

void packPositiveFixInt() {
  List<int> encoded = serialize(1);
  expect(encoded, orderedEquals([1]));
}

void packFixedNegative() {
  List<int> encoded = serialize(-16);
  expect(encoded, orderedEquals([240]));
}

void packUint8() {
  List<int> encoded = serialize(128);
  expect(encoded, orderedEquals([204, 128]));
}

void packUint16() {
  List<int> encoded = serialize(32768);
  expect(encoded, orderedEquals([205, 128, 0]));
}

void packUint32() {
  List<int> encoded = serialize(2147483648);
  expect(encoded, orderedEquals([206, 128, 0, 0, 0]));
}

void packUint64() {
  List<int> encoded = serialize(9223372036854775807);
  expect(encoded, orderedEquals([207, 127, 255, 255, 255, 255, 255, 255, 255]));
}

void packInt8() {
  List<int> encoded = serialize(-128);
  expect(encoded, orderedEquals([208, 128]));
}

void packInt16() {
  List<int> encoded = serialize(-32768);
  expect(encoded, orderedEquals([209, 128, 0]));
}

void packInt32() {
  List<int> encoded = serialize(-2147483648);
  expect(encoded, orderedEquals([210, 128, 0, 0, 0]));
}

void packInt64() {
  List<int> encoded = serialize(-9223372036854775808);
  expect(encoded, orderedEquals([211, 128, 0, 0, 0, 0, 0, 0, 0]));
}

void packFloat32() {
  List<int> encoded = serialize(Float(3.14));
  expect(encoded, orderedEquals([202, 64, 72, 245, 195]));
}

void packDouble() {
  List<int> encoded = serialize(3.14);
  expect(encoded,
      orderedEquals([0xcb, 0x40, 0x09, 0x1e, 0xb8, 0x51, 0xeb, 0x85, 0x1f]));
}

void packString5() {
  List<int> encoded = serialize("hello");
  expect(encoded, orderedEquals([165, 104, 101, 108, 108, 111]));
}

void packString22() {
  List<int> encoded = serialize("hello there, everyone!");
  expect(
      encoded,
      orderedEquals([
        182,
        104,
        101,
        108,
        108,
        111,
        32,
        116,
        104,
        101,
        114,
        101,
        44,
        32,
        101,
        118,
        101,
        114,
        121,
        111,
        110,
        101,
        33
      ]));
}

void packString256() {
  List<int> encoded = serialize(
      "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
  expect(encoded, hasLength(259));
  expect(encoded.sublist(0, 3), orderedEquals([218, 1, 0]));
  expect(encoded.sublist(3, 259), everyElement(65));
}

void packBin8() {
  var data = Uint8List.fromList(List.filled(32, 65));
  List<int> encoded = serialize(ByteData.view(data.buffer));
  expect(encoded.length, equals(34));
  expect(encoded.getRange(0, 2), orderedEquals([BinaryType.Bin8.value, 32]));
  expect(encoded.getRange(2, encoded.length), orderedEquals(data));
}

void packBin16() {
  var data = Uint8List.fromList(List.filled(256, 65));
  List<int> encoded = serialize(ByteData.view(data.buffer));
  expect(encoded.length, equals(256 + 3));
  expect(encoded.getRange(0, 3), orderedEquals([BinaryType.Bin16.value, 1, 0]));
  expect(encoded.getRange(3, encoded.length), orderedEquals(data));
}

void packBin32() {
  var data = Uint8List.fromList(List.filled(65536, 65));
  List<int> encoded = serialize(ByteData.view(data.buffer));
  expect(encoded.length, equals(65536 + 5));
  expect(encoded.getRange(0, 5),
      orderedEquals([BinaryType.Bin32.value, 0, 1, 0, 0]));
  expect(encoded.getRange(5, encoded.length), orderedEquals(data));
}

void packBinOffset() {
  var data = Uint8List.fromList(List.filled(32, 65));
  List<int> encoded = serialize(ByteData.view(data.buffer, 8));
  expect(encoded.length, equals(26));
  expect(encoded.getRange(0, 2), orderedEquals([BinaryType.Bin8.value, 24]));
  expect(encoded.getRange(2, encoded.length),
      orderedEquals(data.getRange(8, data.lengthInBytes)));
}

void packStringArray() {
  List<int> encoded = serialize(["one", "two", "three"]);
  expect(
      encoded,
      orderedEquals([
        147,
        163,
        111,
        110,
        101,
        163,
        116,
        119,
        111,
        165,
        116,
        104,
        114,
        101,
        101
      ]));
}

void packIntToStringMap() {
  List<int> encoded = serialize({1: "one", 2: "two"});
  expect(encoded,
      orderedEquals([130, 1, 163, 111, 110, 101, 2, 163, 116, 119, 111]));
}

void packSmallDateTime() {
  // Epoch time because why not? It should be all 0's.
  var date = ExtTimeStamp(DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
  List<int> encoded = serialize(date);
  expect(encoded, orderedEquals([0xd7, 0xff, 0, 0, 0, 0, 0, 0, 0, 0]));
  date = ExtTimeStamp(DateTime.utc(2018, 8, 21, 21, 56, 56, 200));
  encoded = serialize(date);
  expect(
      encoded, orderedEquals([0xd7, 0xff, 47, 175, 8, 0, 91, 124, 137, 224]));
}

void packPastDate() {
  var date = ExtTimeStamp(DateTime.utc(1932, 2, 23, 21, 53, 45, 500));
  List<int> encoded = serialize(date);
  expect(
      encoded,
      orderedEquals([
        0xc7,
        12,
        0xff,
        29,
        205,
        101,
        0,
        255,
        255,
        255,
        255,
        184,
        204,
        65,
        94
      ]));
  var date2 = DateTime.utc(1969, 12, 31, 19, 30);
  // Tests "negative near epoch", plus raw date/time rather than wrapping in
  // ExtTimeStamp.
  encoded = serialize(date2);
  expect(
      encoded,
      orderedEquals(
          [199, 12, 255, 0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 192, 184]));
}

void packCustomExtension() {
  var message = new TestExtension(1, "one", {2: "two"});
  registerExtension(message);
  List<int> encoded = serialize(message);
  expect(
      encoded,
      orderedEquals(
          [0xc7, 11, 1, 1, 163, 111, 110, 101, 129, 2, 163, 116, 119, 111]));
}

void packNestedCustomExtension() {
  var inner = new TestExtension(1, "one", {2: "two"});
  var outer = new OuterExtension("three", true, [4, 5, 6], inner);
  registerExtension(outer);
  List<int> encoded = serialize(outer);
  expect(
      encoded,
      orderedEquals([
        0xc7,
        25,
        2,
        165,
        116,
        104,
        114,
        101,
        101,
        195,
        147,
        4,
        5,
        6,
        0xc7,
        11,
        1,
        1,
        163,
        111,
        110,
        101,
        129,
        2,
        163,
        116,
        119,
        111
      ]));
}

// Test unpacking
void unpackNull() {
  Uint8List data = new Uint8List.fromList([0xc0]);
  var value = deserialize(data);
  expect(value, isNull);
}

void unpackFalse() {
  Uint8List data = Uint8List.fromList([0xc2]);
  var value = deserialize(data);
  expect(value, isFalse);
}

void unpackTrue() {
  Uint8List data = Uint8List.fromList([0xc3]);
  var value = deserialize(data);
  expect(value, isTrue);
}

void unpackString5() {
  Uint8List data = new Uint8List.fromList([165, 104, 101, 108, 108, 111]);
  var value = deserialize(data);
  expect(value, isString);
  expect(value, equals("hello"));
}

void unpackString22() {
  Uint8List data = new Uint8List.fromList([
    182,
    104,
    101,
    108,
    108,
    111,
    32,
    116,
    104,
    101,
    114,
    101,
    44,
    32,
    101,
    118,
    101,
    114,
    121,
    111,
    110,
    101,
    33
  ]);
  var value = deserialize(data);
  expect(value, isString);
  expect(value, equals("hello there, everyone!"));
}

void unpackPositiveFixInt() {
  Uint8List data = Uint8List.fromList([1]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(1));
}

void unpackNegativeFixInt() {
  Uint8List data = Uint8List.fromList([240]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(-16));
}

void unpackUint8() {
  Uint8List data = Uint8List.fromList([204, 128]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(128));
}

void unpackUint16() {
  Uint8List data = Uint8List.fromList([205, 128, 0]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(32768));
}

void unpackUint32() {
  Uint8List data = Uint8List.fromList([206, 128, 0, 0, 0]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(2147483648));
}

void unpackUint64() {
  // Dart 2 doesn't support true Uint64 without using BigInt
  Uint8List data =
      Uint8List.fromList([207, 127, 255, 255, 255, 255, 255, 255, 255]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(9223372036854775807));
}

void unpackInt8() {
  Uint8List data = Uint8List.fromList([208, 128]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(-128));
}

void unpackInt16() {
  Uint8List data = Uint8List.fromList([209, 128, 0]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(-32768));
}

void unpackInt32() {
  Uint8List data = Uint8List.fromList([210, 128, 0, 0, 0]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(-2147483648));
}

void unpackInt64() {
  Uint8List data = Uint8List.fromList([211, 128, 0, 0, 0, 0, 0, 0, 0]);
  var value = deserialize(data);
  expect(value, isInt);
  expect(value, equals(-9223372036854775808));
}

void unpackFloat32() {
  Uint8List data = Uint8List.fromList([202, 64, 72, 245, 195]);
  var value = deserialize(data);
  expect((value as double).toStringAsPrecision(3), equals('3.14'));
}

void unpackDouble() {
  Uint8List data = Uint8List.fromList(
      [0xcb, 0x40, 0x09, 0x1e, 0xb8, 0x51, 0xeb, 0x85, 0x1f]);
  var value = deserialize(data);
  expect(value, equals(3.14));
}

void unpackString256() {
  Uint8List data =
      new Uint8List.fromList([218, 1, 0]..addAll(new List.filled(256, 65)));
  var value = deserialize(data);
  expect(value, isString);
  expect(
      value,
      equals(
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"));
}

void unpackStringArray() {
  Uint8List data = new Uint8List.fromList([
    147,
    163,
    111,
    110,
    101,
    163,
    116,
    119,
    111,
    165,
    116,
    104,
    114,
    101,
    101
  ]);
  var value = deserialize(data);
  expect(value, isList);
  expect(value, orderedEquals(["one", "two", "three"]));
}

void unpackIntToStringMap() {
  Uint8List data = new Uint8List.fromList(
      [130, 1, 163, 111, 110, 101, 2, 163, 116, 119, 111]);
  var value = deserialize(data);
  expect(value, isMap);
  expect(value[1], equals("one"));
  expect(value[2], equals("two"));
}

void unpackSmallDateTime() {
  var data = <int>[0xd7, 0xff, 0, 0, 0, 0, 0, 0, 0, 0];
  var value = deserialize(data);
  expect(value, equals(DateTime.fromMillisecondsSinceEpoch(0)));
  data = <int>[0xd7, 0xff, 47, 175, 8, 0, 91, 124, 180, 16];
  value = deserialize(data);
  expect((value as DateTime).toUtc(),
      equals(DateTime.utc(2018, 8, 22, 0, 56, 56, 200)));
}

void unpackPastDate() {
  var data = <int>[
    0xc7,
    12,
    0xff,
    29,
    205,
    101,
    0,
    255,
    255,
    255,
    255,
    184,
    204,
    121,
    158
  ];

  var value = deserialize(data) as DateTime;
  expect(value.toUtc(), equals(DateTime.utc(1932, 2, 24, 1, 53, 45, 500)));

  data = <int>[
    199,
    12,
    255,
    0,
    0,
    0,
    0,
    255,
    255,
    255,
    255,
    255,
    255,
    248,
    248
  ];
  value = deserialize(data);
  expect(value.toUtc(), equals(DateTime.utc(1969, 12, 31, 23, 30)));
}

void unpackCustomExtension() {
  var data = <int>[
    0xc7,
    11,
    1,
    1,
    163,
    111,
    110,
    101,
    129,
    2,
    163,
    116,
    119,
    111
  ];
  TestExtension value = deserialize(data);
  expect(value.a, equals(1));
  expect(value.b, equals("one"));
  expect(value.c, equals({2: "two"}));
}

void unpackNestedCustomExtension() {
  var data = <int>[
    0xc7,
    25,
    2,
    165,
    116,
    104,
    114,
    101,
    101,
    195,
    147,
    4,
    5,
    6,
    0xc7,
    11,
    1,
    1,
    163,
    111,
    110,
    101,
    129,
    2,
    163,
    116,
    119,
    111
  ];
  OuterExtension value = deserialize(data);
  expect(value.a, equals("three"));
  expect(value.b, isTrue);
  expect(value.c, orderedEquals([4, 5, 6]));
  expect(value.d.a, equals(1));
  expect(value.d.b, equals("one"));
  expect(value.d.c, equals({2: "two"}));
}
