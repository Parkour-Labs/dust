import 'package:dust/dust.dart';

part 'example.dust.dart';

@Model()
abstract class Todo with _$Todo {
  Todo._();

  factory Todo({
    required String title,
  }) = _Todo;
}
