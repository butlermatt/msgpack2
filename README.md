# MsgPack for Dart

A full-featured MsgPack library for Dart 1.x and 2.x.

## Attribution

This package was originally forked from [msgpack](https://pub.dartlang.org/packages/msgpack). Due to the number of 
incompatible refactorings and loss of backwards compatibility, the decision was made to spin it off as a new package.
This package contains numerous enhancements over the original MsgPack implementation which should help with performance
in many places (see [benchmarks](benchmarks.md)), as well as a more complete testing suite.

## Usage


Because this project relies on Dart Libraries which contain inconsistencies between
Dart 1.x and Dart 2.x, there are two versions of the this package maintained.

If you want to use this package for Dart projects with Dart 2.x, please ensure your
version dependencies are set to:

```yaml
  dependencies:
    msgpack2: ^2.0.0
``` 

If you want to use this package for Dart projects with Dart 1.x, please ensure your
version dependencies are set to:

```yaml
  dependencies:
    msgpack2: ^1.0.0
```

## Simple Example

```dart
import "dart:typed_data";

import "package:msgpack/msgpack.dart";

main() {
  var binary = new Uint8List.fromList(
    new List<int>.generate(40, (int i) => i)
  ).buffer.asByteData();

  var data = {
    "String": "Hello World",
    "Integer": 42,
    "Double": 45.29,
    "Integer List": [1, 2, 3],
    "Binary": binary,
    "Map": {
      1: 2,
      3: 4
    }
  };

  List<int> packed = pack(data);
  Map unpacked = unpack(packed);

  print(unpacked);
}
```
