import 'dart:ffi';

import 'package:beacons/ffi.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Text('${fnv64Hash("hello")}'),
          Text('${testHash("hello")}'),
          Text('${testList()}'),
        ],
      )),
    );
  }
}

int testHash(String name) {
  final ptr = name.toNativeUtf8(allocator: malloc);
  final res = getNativeBindings().make_label(ptr);
  malloc.free(ptr);
  return res;
}

List<int> testList() {
  return getNativeBindings().test_array_u8().ptr.asTypedList(5).toList();
}
