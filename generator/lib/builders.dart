import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'model_repository_generator.dart';

// Builder modelRepositoryBuilder(BuilderOptions options) =>
//     SharedPartBuilder([ModelRepositoryGenerator()], 'model_repository');

Builder dustBuilder(BuilderOptions options) {
  return PartBuilder(
    [ModelRepositoryGenerator()],
    '.dust.dart',
    header: '''
// GENERATED CODE - DO NOT MODIFY BY HAND
    ''',
    options: options,
  );
}
