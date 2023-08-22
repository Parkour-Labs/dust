import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'model_repository_generator.dart';

Builder modelRepositoryBuilder(BuilderOptions options) =>
    SharedPartBuilder([ModelRepositoryGenerator()], 'model_repository');
