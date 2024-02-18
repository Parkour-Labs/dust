import 'package:qinhuai/annotations.dart';
import 'package:qinhuai/store.dart';

part 'example.dust.dart';

@Model()
class Todo with _$Todo {
  Todo._();

  factory Todo({
    required String title,
    String? description,
    @Default(false) bool completed,
  }) = _Todo;
}
