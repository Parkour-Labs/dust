import 'dart:convert' show utf8;
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

Never fail(String msg, Element element) {
  throw InvalidGenerationSourceError(msg, element: element);
}

/// Hashes the string `s` to a value of desired.
int fnv64Hash(String s) {
  const int kPrime = 1099511628211;
  const int kBasis = -3750763034362895579; // 14695981039346656037 - 2^64
  var res = kBasis;
  for (final c in utf8.encode(s)) {
    res = (res * kPrime) ^ c;
  }
  return res;
}

ConstructorElement checkValidClass(Element modelClass) {
  if (modelClass is! ClassElement || modelClass is EnumElement || modelClass is MixinElement) {
    fail('Only classes may be annotated with @Model().', modelClass);
  }

  final constructor = modelClass.constructors.where((c) {
    final offset = c.periodOffset;
    return offset != null && c.name.substring(offset + 1) == '_';
  }).firstOrNull;

  if (constructor == null) {
    fail('Class needs a constructor with name `_`.', modelClass);
  }
  // TODO: check constructor.parameters

  return constructor;
}

/*
void checkValidPropertiesConstructor(
  List<PropertyInfo> properties,
  ConstructorElement constructor,
) {
  if (properties.map((e) => e.isarName).toSet().length != properties.length) {
    fail(
      'Two or more properties have the same name.',
      constructor.enclosingElement,
    );
  }

  final unknownConstructorParameter = constructor.parameters
      .where(
        (p) => p.isRequired && !properties.any((e) => e.dartName == p.name),
      )
      .firstOrNull;
  if (unknownConstructorParameter != null) {
    fail(
      'Constructor parameter does not match a property.',
      unknownConstructorParameter,
    );
  }
}

Set<String> _getEmbeddedDartNames(ClassElement element) {
  void fillNames(Set<String> names, ClassElement element) {
    for (final property in element.allAccessors) {
      final type = property.type.scalarType.element;
      if (type is ClassElement && type.embeddedAnnotation != null) {
        if (names.add(type.name)) {
          fillNames(names, type);
        }
      }
    }
  }

  final names = <String>{};
  fillNames(names, element);
  return names;
}

PropertyInfo _analyzePropertyInfo(
  PropertyInducingElement property,
  ConstructorElement constructor,
  int propertyIndex,
  bool isId,
) {
  final dartType = property.type;
  Map<String, dynamic>? enumMap;
  String? enumPropertyName;

  late final IsarType type;
  if (dartType.scalarType.element is EnumElement) {
    final enumClass = dartType.scalarType.element! as EnumElement;
    final enumElements = enumClass.fields.where((f) => f.isEnumConstant).toList();

    final enumProperty = enumClass.enumValueProperty;
    enumPropertyName = enumProperty?.name ?? 'index';
    if (enumProperty != null && enumProperty.nonSynthetic is PropertyAccessorElement) {
      fail('Only fields are supported for enum properties', enumProperty);
    }

    final enumIsarType = enumProperty == null ? IsarType.byte : enumProperty.type.propertyType;
    if (enumIsarType != IsarType.byte &&
        enumIsarType != IsarType.int &&
        enumIsarType != IsarType.long &&
        enumIsarType != IsarType.string) {
      fail('Unsupported enum property type.', enumProperty);
    }

    type = dartType.isDartCoreList ? enumIsarType!.listType : enumIsarType!;
    enumMap = {};
    for (var i = 0; i < enumElements.length; i++) {
      final element = enumElements[i];
      dynamic propertyValue = i;
      if (enumProperty != null) {
        final property = element.computeConstantValue()!.getField(enumProperty.name)!;
        propertyValue =
            property.toBoolValue() ?? property.toIntValue() ?? property.toDoubleValue() ?? property.toStringValue();
      }

      if (propertyValue == null) {
        fail(
          'Null values are not supported for enum properties.',
          enumProperty,
        );
      }

      if (enumMap.values.contains(propertyValue)) {
        fail(
          'Enum property has duplicate values.',
          enumProperty,
        );
      }
      enumMap[element.name] = propertyValue;
    }
  } else {
    if (dartType.propertyType != null) {
      type = dartType.propertyType!;
    } else if (dartType.supportsJsonConversion) {
      type = IsarType.json;
    } else {
      fail(
        'Unsupported type. Please add @embedded to the type or implement '
        'toJson() and fromJson() methods or annotate the property with '
        '@ignore let Isar to ignore it.',
        property,
      );
    }
  }

  final nullable = dartType.nullabilitySuffix != NullabilitySuffix.none || dartType is DynamicType;
  final elementNullable = type.isList
      ? dartType.scalarType.nullabilitySuffix != NullabilitySuffix.none || dartType.scalarType is DynamicType
      : null;
  if (isId) {
    if (type != IsarType.long && type != IsarType.string) {
      fail('Only int and String properties can be used as id.', property);
    } else if (nullable) {
      fail('Id properties must not be nullable.', property);
    }
  }

  if ((type == IsarType.byte && nullable) || (type == IsarType.byteList && (elementNullable ?? false))) {
    fail('Bytes must not be nullable.', property);
  }

  final constructorParameter = constructor.parameters.where((p) => p.name == property.name).firstOrNull;
  int? constructorPosition;
  late DeserializeMode mode;
  if (constructorParameter != null) {
    if (constructorParameter.type != property.type) {
      fail(
        'Constructor parameter type does not match property type',
        constructorParameter,
      );
    }
    mode = constructorParameter.isNamed ? DeserializeMode.namedParam : DeserializeMode.positionalParam;
    constructorPosition = constructor.parameters.indexOf(constructorParameter);
  } else {
    mode = property.setter == null ? DeserializeMode.none : DeserializeMode.assign;
  }

  return PropertyInfo(
    index: propertyIndex,
    dartName: property.name,
    isarName: property.isarName,
    typeClassName: type == IsarType.json ? dartType.element!.name! : dartType.scalarType.element!.name!,
    targetIsarName: type.isObject ? dartType.scalarType.element!.isarName : null,
    type: type,
    isId: isId,
    enumMap: enumMap,
    enumProperty: enumPropertyName,
    nullable: nullable,
    elementNullable: elementNullable,
    defaultValue: constructorParameter?.defaultValueCode ?? _defaultValue(dartType),
    elementDefaultValue: type.isList ? _defaultValue(dartType.scalarType) : null,
    utc: type.isDate && property.hasUtcAnnotation,
    mode: mode,
    assignable: property.setter != null,
    constructorPosition: constructorPosition,
  );
}

String _defaultValue(DartType type) {
  if (type.nullabilitySuffix == NullabilitySuffix.question || type is DynamicType) {
    return 'null';
  } else if (type.isDartCoreInt) {
    if (type.propertyType == IsarType.byte) {
      return '0';
    } else if (type.propertyType == IsarType.int) {
      return '$_nullInt';
    } else {
      return '$_nullLong';
    }
  } else if (type.isDartCoreDouble) {
    return 'double.nan';
  } else if (type.isDartCoreBool) {
    return 'false';
  } else if (type.isDartCoreString) {
    return "''";
  } else if (type.isDartCoreDateTime) {
    return 'DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal()';
  } else if (type.isDartCoreList) {
    return 'const <${type.scalarType}>[]';
  } else if (type.isDartCoreMap) {
    return 'const <String, dynamic>{}';
  } else {
    final element = type.element!;
    if (element is EnumElement) {
      final firstConst = element.fields.where((f) => f.isEnumConstant).first;
      return '${element.name}.${firstConst.name}';
    } else if (element is ClassElement) {
      final defaultConstructor = _checkValidClass(element);
      var code = '${element.name}(';
      for (final param in defaultConstructor.parameters) {
        if (!param.isOptional) {
          if (param.isNamed) {
            code += '${param.name}: ';
          }
          code += _defaultValue(param.type);
          code += ', ';
        }
      }
      return '$code)';
    }
  }

  throw UnimplementedError('This should not happen');
}

Iterable<IndexInfo> analyzeObjectIndex(
  List<PropertyInfo> properties,
  PropertyInducingElement element,
) sync* {
  for (final index in element.indexAnnotations) {
    final indexProperties = [element.isarName, ...index.composite];

    if (indexProperties.toSet().length != indexProperties.length) {
      fail('Composite index contains duplicate properties.', element);
    } else if (indexProperties.length > 3) {
      fail('Composite indexes cannot have more than 3 properties.', element);
    }

    for (var i = 0; i < indexProperties.length; i++) {
      final propertyName = indexProperties[i];
      final property = properties.where((it) => it.isarName == propertyName).firstOrNull;
      if (property == null) {
        fail('Property does not exist: "$propertyName".', element);
      } else if (property.isId) {
        fail('Ids cannot be indexed', element);
      } else if (property.type.isFloat) {
        fail('Double properties cannot be indexed', element);
      } else if (property.type.isObject) {
        fail('Embedded object properties cannot be indexed', element);
      } else if (property.type == IsarType.json) {
        fail('JSON properties cannot be indexed', element);
      } else if (property.type.isList) {
        fail('List properties cannot be indexed', element);
      } else if (property.type.isString && i != indexProperties.length - 1 && !index.hash) {
        fail(
          'Only the last property of a non-hashed composite index can be a '
          'String.',
          element,
        );
      }
    }

    final name = index.name ?? indexProperties.join('_');
    _checkIsarName(name, element);

    final objectIndex = IndexInfo(
      name: name,
      properties: indexProperties,
      unique: index.unique,
      hash: index.hash,
    );

    yield objectIndex;
  }
}
*/
