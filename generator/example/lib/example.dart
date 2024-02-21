import 'package:dust/dust.dart';

part 'example.dust.dart';

@Model()
class Todo with _$Todo {
  Todo._();

  factory Todo({
    required String title,
    String? description,
    @DustDft(false) bool completed,
  }) = _Todo;
}
