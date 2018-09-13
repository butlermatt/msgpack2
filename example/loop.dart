import "package:msgpack2/msgpack.dart";

main(List<String> args) async {
  var count = 5000;

  if (args.length == 1) {
    count = int.parse(args[0]);
  }

  var data = {
    "responses": [
      {
        "rid": 0,
        "updates": [
          [6, 21901.11328125, "2015-11-28T13:19:13.164-05:00"],
          [8, 31.844969287790363, "2015-11-28T13:19:13.164-05:00"]
        ]
      }
    ],
    "msg": 99
  };
  var i = 0;
  var watch = new Stopwatch();
  var counts = [];
  while (true) {
    watch.start();
    var packed = serialize(data);
    deserialize(packed);
    watch.stop();
    counts.add(watch.elapsedMicroseconds);
    watch.reset();

    i++;

    if (i == count) {
      break;
    }
  }

  var avg = counts.reduce((a, b) => a + b) / counts.length;
  print("Average Time: ${avg} microseconds");
}
