import 'package:dust/dust.dart';

part 'example.bak.dust.dart';

abstract class Todo with _$Todo {
  Todo._();

  factory Todo({
    required String title,
  }) = _Todo;
}
