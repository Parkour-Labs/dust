import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ffi.dart';

void main() {
  runApp(const MyApp());
}

List<int> testList() {
  return Ffi.instance().beaconsBindings.test_array_u8().ptr.asTypedList(5).toList();
}

int testHash(String name) {
  final ptr = name.toNativeUtf8(allocator: malloc);
  final res = Ffi.instance().beaconsBindings.hash(ptr);
  malloc.free(ptr);
  return res;
}

Future<bool> testAsync() async {
  final Completer<bool> completer = Completer();
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is bool) {
        completer.complete(data);
      } else {
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      }
    });

  // Do the tests in a separate isolate and send the results back.
  Isolate.spawn((SendPort sendPort) async {
    testFfiParamPassing();
    // stressTestFfiDropping(10);
    sendPort.send(true);
  }, receivePort.sendPort);

  return completer.future;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Tests'),
        ),
        body: Center(
          child: FutureBuilder(
            future: testAsync(),
            builder: (context, snapshot) => snapshot.hasData && snapshot.data!
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('${testList()}'),
                      Text('${testHash("hello")}'),
                      const Text('All tests passed!'),
                    ],
                  )
                : const CircularProgressIndicator.adaptive(),
          ),
        ),
      ),
    );
  }
}

const int kIntMin = -9223372036854775808;

void testFfiParamPassing() {
  final bindings = Ffi.instance().beaconsBindings;

  final id = bindings.test_id();
  assert(id.high == 233 && id.low == 666);
  assert(bindings.test_id_input(id));

  final uid = bindings.test_id_unsigned();
  assert(uid.high == kIntMin + 233 && uid.low == kIntMin + 666);
  assert(bindings.test_id_input_unsigned(uid));

  final edge = bindings.test_edge();
  assert(edge.src.high == id.high &&
      edge.src.low == id.low &&
      edge.label == -kIntMin + 1 &&
      edge.dst.high == uid.high &&
      edge.dst.low == uid.low);
  assert(bindings.test_edge_input(edge));

  final arrayUint8 = bindings.test_array_u8();
  assert(arrayUint8.len == 5 && listEquals(arrayUint8.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
  bindings.drop_array_u8(arrayUint8);

  final arrayPairIdId = bindings.test_array_pair_id_id();
  assert(arrayPairIdId.len == 2);
  {
    final first = arrayPairIdId.ptr.elementAt(0).ref;
    final second = arrayPairIdId.ptr.elementAt(1).ref;
    assert(first.first.high == id.high && first.first.low == id.low);
    assert(first.second.high == uid.high && first.second.low == uid.low);
    assert(second.first.high == 0 && second.first.low == 1);
    assert(second.second.high == 1 && second.second.low == 0);
  }
  bindings.drop_array_id_id(arrayPairIdId);

  final arrayPairIdEdge = bindings.test_array_pair_id_edge();
  assert(arrayPairIdEdge.len == 2);
  {
    final first = arrayPairIdEdge.ptr.elementAt(0).ref;
    final second = arrayPairIdEdge.ptr.elementAt(1).ref;
    assert(first.first.high == id.high && first.first.low == id.low);
    assert(first.second.src.high == edge.src.high &&
        first.second.src.low == edge.src.low &&
        first.second.label == edge.label &&
        first.second.dst.high == edge.dst.high &&
        first.second.dst.low == edge.dst.low);
    assert(second.first.high == 1 && second.first.low == 1);
    assert(second.second.src.high == 0 &&
        second.second.src.low == 1 &&
        second.second.label == 1 &&
        second.second.dst.high == 1 &&
        second.second.dst.low == 0);
  }
  bindings.drop_array_id_edge(arrayPairIdEdge);

  final optionNone = bindings.test_option_u64_none();
  assert(optionNone.tag == 0);

  final optionUint64 = bindings.test_option_u64_some();
  assert(optionUint64.tag == 1 && optionUint64.some == 233);

  final optionArrayUint8 = bindings.test_option_array_u8_some();
  assert(optionArrayUint8.tag == 1 &&
      optionArrayUint8.some.len == 5 &&
      listEquals(optionArrayUint8.some.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
  bindings.drop_option_array_u8(optionArrayUint8);

  final optionEdge = bindings.test_option_edge_some();
  assert(optionEdge.tag == 1 &&
      optionEdge.some.src.high == id.high &&
      optionEdge.some.src.low == id.low &&
      optionEdge.some.label == -kIntMin + 1 &&
      optionEdge.some.dst.high == uid.high &&
      optionEdge.some.dst.low == uid.low);

  final arrayPairUint64EventData = bindings.test_array_pair_u64_event_data();
  assert(arrayPairUint64EventData.len == 7);
  {
    for (var i = 0; i < 7; i++) {
      assert(arrayPairUint64EventData.ptr.elementAt(i).ref.first == i + 1);
      assert(arrayPairUint64EventData.ptr.elementAt(i).ref.second.tag == i);
    }
    final node = arrayPairUint64EventData.ptr.elementAt(0).ref.second.union.node;
    assert(node.tag == 1 && node.some == 233);
    final atom = arrayPairUint64EventData.ptr.elementAt(1).ref.second.union.atom;
    assert(atom.tag == 1 && atom.some.len == 5 && listEquals(atom.some.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
    final edge = arrayPairUint64EventData.ptr.elementAt(2).ref.second.union.edge;
    assert(edge.tag == 1 &&
        edge.some.src.high == id.high &&
        edge.some.src.low == id.low &&
        edge.some.label == -kIntMin + 1 &&
        edge.some.dst.high == uid.high &&
        edge.some.dst.low == uid.low);
    final multiedgeInsert = arrayPairUint64EventData.ptr.elementAt(3).ref.second.union.multiedgeInsert;
    assert(multiedgeInsert.first.high == id.high &&
        multiedgeInsert.first.low == id.low &&
        multiedgeInsert.second.high == uid.high &&
        multiedgeInsert.second.low == uid.low);
    final multiedgeRemove = arrayPairUint64EventData.ptr.elementAt(4).ref.second.union.multiedgeRemove;
    assert(multiedgeRemove.first.high == uid.high &&
        multiedgeRemove.first.low == uid.low &&
        multiedgeRemove.second.high == id.high &&
        multiedgeRemove.second.low == id.low);
    final backedgeInsert = arrayPairUint64EventData.ptr.elementAt(5).ref.second.union.backedgeInsert;
    assert(backedgeInsert.first.high == id.high &&
        backedgeInsert.first.low == id.low &&
        backedgeInsert.second.high == uid.high &&
        backedgeInsert.second.low == uid.low);
    final backedgeRemove = arrayPairUint64EventData.ptr.elementAt(6).ref.second.union.backedgeRemove;
    assert(backedgeRemove.first.high == uid.high &&
        backedgeRemove.first.low == uid.low &&
        backedgeRemove.second.high == id.high &&
        backedgeRemove.second.low == id.low);
  }
  bindings.drop_array_u64_event_data(arrayPairUint64EventData);
}

void stressTestFfiDropping(int count) {
  final bindings = Ffi.instance().beaconsBindings;
  for (var i = 0; i < count; i++) {
    final arrayUint8 = bindings.test_array_u8_big(256000000);
    bindings.drop_array_u8(arrayUint8);
    final arrayPairUint64EventData = bindings.test_array_pair_u64_event_data_big(10, 25600000);
    bindings.drop_array_u64_event_data(arrayPairUint64EventData);
  }
}
