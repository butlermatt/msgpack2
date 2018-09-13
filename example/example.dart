import "package:msgpack2/msgpack.dart";

import "dart:typed_data";
import "dart:math";

main() {
  var byteList = new Uint8List(1024 * 1024 * 20);
  var random = new Random();
  for (var i = 0; i < byteList.lengthInBytes; i++) {
    byteList[i] = random.nextInt(255);
  }
  var byteData = byteList.buffer
      .asByteData(byteList.offsetInBytes, byteList.lengthInBytes);

  var data = {
    "String": "Hello World",
    "Integer": 42,
    "Double": 45.29,
    "Integer List": [1, 2, 3],
    "Map": {1: 2, 3: 4},
    "Large Number": 1455232609379,
    "Negative Large Number": -1455232609379,
    "Simple Negative": -59,
    "Bytes": byteData,
    "Uint16": 65235
  };

  List<int> packed = serialize(data);
  Map unpacked = deserialize(packed);

  print("Original: $data");
  print("Unpacked: $unpacked");

  ByteData gotByteData = unpacked["Bytes"];

  if (gotByteData.lengthInBytes != byteData.lengthInBytes) {
    throw "Byte data is not the correct amount of bytes.";
  }

  for (var i = 0; i < gotByteData.lengthInBytes; i++) {
    if (byteData.getUint8(i) != gotByteData.getUint8(i)) {
      throw "Byte data is not the correct content.";
    }
  }
}
