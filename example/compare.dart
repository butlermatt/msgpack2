import "package:msgpack2/msgpack.dart";

main() {
  var data = [
    53.43750000000001,
    5883939484804398999,
    "unpacked",
    5993939,
    5.48384888,
    5.5,
    -45,
    -500,
    -482858587484,
    -64000,
    new Float(5.38),
    {}
  ];

  var a = serialize(data);
  var b = serialize(data);

  print(a);
  print(b);
}
