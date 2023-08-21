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
  return Ffi.instance().beaconsTestBindings.test_array_u8().ptr.asTypedList(5).toList();
}

int testHash(String name) {
  final ptr = name.toNativeUtf8(allocator: malloc);
  final res = Ffi.instance().beaconsBindings.make_label(ptr);
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
  final testBindings = Ffi.instance().beaconsTestBindings;

  final id = testBindings.test_id();
  assert(id.high == 233 && id.low == 666);
  assert(testBindings.test_id_input(id));

  final uid = testBindings.test_id_unsigned();
  assert(uid.high == kIntMin + 233 && uid.low == kIntMin + 666);
  assert(testBindings.test_id_input_unsigned(uid));

  final edge = testBindings.test_edge();
  assert(edge.src == id && edge.label == -kIntMin + 1 && edge.dst == uid);
  assert(testBindings.test_edge_input(edge));

  final arrayUint8 = testBindings.test_array_u8();
  assert(arrayUint8.len == 5 && listEquals(arrayUint8.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
  bindings.drop_array_u8(arrayUint8);

  final arrayPairIdId = testBindings.test_array_pair_id_id();
  assert(arrayPairIdId.len == 2);
  {
    final first = arrayPairIdId.ptr.elementAt(0).ref;
    final second = arrayPairIdId.ptr.elementAt(1).ref;
    assert(first.first == id && first.second == uid);
    assert(second.first.high == 0 && second.first.low == 1);
    assert(second.second.high == 1 && second.second.low == 0);
  }
  bindings.drop_array_id_id(arrayPairIdId);

  final arrayPairIdEdge = testBindings.test_array_pair_id_edge();
  assert(arrayPairIdEdge.len == 2);
  {
    final first = arrayPairIdEdge.ptr.elementAt(0).ref;
    final second = arrayPairIdEdge.ptr.elementAt(1).ref;
    assert(first.first == id);
    assert(first.second.src == edge.src && first.second.label == edge.label && first.second.dst == edge.dst);
    assert(second.first.high == 1 && second.first.low == 1);
    assert(second.second.src.high == 0 &&
        second.second.src.low == 1 &&
        second.second.label == 1 &&
        second.second.dst.high == 1 &&
        second.second.dst.low == 0);
  }
  bindings.drop_array_id_edge(arrayPairIdEdge);

  final optionNone = testBindings.test_option_u64_none();
  assert(optionNone.tag == 0);

  final optionUint64 = testBindings.test_option_u64_some();
  assert(optionUint64.tag == 1 && optionUint64.some == 233);

  final optionArrayUint8 = testBindings.test_option_array_u8_some();
  assert(optionArrayUint8.tag == 1 &&
      optionArrayUint8.some.len == 5 &&
      listEquals(optionArrayUint8.some.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
  bindings.drop_option_array_u8(optionArrayUint8);

  final optionEdge = testBindings.test_option_edge_some();
  assert(optionEdge.tag == 1 &&
      optionEdge.some.src == id &&
      optionEdge.some.label == -kIntMin + 1 &&
      optionEdge.some.dst == uid);

  final arrayPairUint64EventData = testBindings.test_array_pair_u64_event_data();
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
    assert(edge.tag == 1 && edge.some.src == id && edge.some.label == -kIntMin + 1 && edge.some.dst == uid);
    final multiedgeInsert = arrayPairUint64EventData.ptr.elementAt(3).ref.second.union.multiedgeInsert;
    assert(multiedgeInsert.first == id && multiedgeInsert.second == uid);
    final multiedgeRemove = arrayPairUint64EventData.ptr.elementAt(4).ref.second.union.multiedgeRemove;
    assert(multiedgeRemove.first == uid && multiedgeRemove.second == id);
    final backedgeInsert = arrayPairUint64EventData.ptr.elementAt(5).ref.second.union.backedgeInsert;
    assert(backedgeInsert.first == id && backedgeInsert.second == uid);
    final backedgeRemove = arrayPairUint64EventData.ptr.elementAt(6).ref.second.union.backedgeRemove;
    assert(backedgeRemove.first == uid && backedgeRemove.second == id);
  }
  bindings.drop_array_u64_event_data(arrayPairUint64EventData);
}

void stressTestFfiDropping(int count) {
  final bindings = Ffi.instance().beaconsBindings;
  final testBindings = Ffi.instance().beaconsTestBindings;

  for (var i = 0; i < count; i++) {
    final arrayUint8 = testBindings.test_array_u8_big(256000000);
    bindings.drop_array_u8(arrayUint8);
    final arrayPairUint64EventData = testBindings.test_array_pair_u64_event_data_big(10, 25600000);
    bindings.drop_array_u64_event_data(arrayPairUint64EventData);
  }
}
