```dart
/// Converts [DartType] to [FieldType].
FieldType convertType(DartType rawType, ParameterElement elem) {
  final type = resolve(rawType, elem);
  final constraints =
      kConstraintsAnnotation.annotationsOfExact(elem).firstOrNull;
  var sticky = constraints?.getField('sticky')?.toBoolValue();
  var acyclic = constraints?.getField('acyclic')?.toBoolValue();

  if (type.element.name == 'Atom' ||
      type.element.name == 'AtomOption' ||
      type.element.name == 'AtomDefault') {
    if (type.typeArguments.length != 1) {
      fail(
        'Incorrect number of type arguments in `$type` (expected 1).',
        elem,
      );
    }
    final inner = resolve(type.typeArguments.single, elem);
    final value = kSerializableAnnotation
        .annotationsOfExact(elem)
        .firstOrNull
        ?.getField('serializer');
    final serializer =
        (value != null) ? construct(value, elem) : emitSerializer(inner);
    if (serializer == null) {
      fail(
        'Failed to synthesize serializer for type `$inner`. '
        'Please specify one using `@Serializable(serializerInstance)`. ',
        elem,
      );
    }
    if (type.element.name == 'Atom') {
      if (sticky != null) {
        fail('Sticky constraint is already implied here.', elem);
      }
      if (acyclic != null) {
        fail('Acyclic constraint cannot be applied here.', elem);
      }
      return AtomType(inner, serializer);
    } else if (type.element.name == 'AtomOption') {
      if (acyclic != null) {
        fail('Acyclic constraint cannot be applied here.', elem);
      }
      return AtomOptionType(inner, serializer, sticky: sticky == true);
    } else if (type.element.name == 'AtomDefault') {
      final value = kDefaultAnnotation
          .annotationsOfExact(elem)
          .firstOrNull
          ?.getField('defaultValue');
      final defaultValue = (value != null) ? construct(value, elem) : null;
      if (defaultValue == null) {
        fail(
          'Please specify a default value using `@Default(defaultValue)`. ',
          elem,
        );
      }
      if (acyclic != null) {
        fail('Acyclic constraint cannot be applied here.', elem);
      }
      return AtomDefaultType(inner, serializer, defaultValue,
          sticky: sticky == true);
    }
  }

  if (type.element.name == 'Link' ||
      type.element.name == 'LinkOption' ||
      type.element.name == 'Multilinks') {
    if (type.typeArguments.length != 1) {
      fail(
        'Incorrect number of type arguments in `$type` (expected 1).',
        elem,
      );
    }
    final inner = resolve(type.typeArguments.single, elem);
    if (type.element.name == 'Link') {
      if (sticky != null) {
        fail('Sticky constraint is already implied here.', elem);
      }
      return LinkType(inner, acyclic: acyclic == true);
    } else if (type.element.name == 'LinkOption') {
      return LinkOptionType(inner,
          sticky: sticky == true, acyclic: acyclic == true);
    } else if (type.element.name == 'Multilinks') {
      return MultilinksType(inner,
          sticky: sticky == true, acyclic: acyclic == true);
    }
  }

  if (type.element.name == 'Backlinks') {
    if (type.typeArguments.length != 1) {
      fail(
        'Incorrect number of type arguments in `$type` (expected 1).',
        elem,
      );
    }
    final inner = resolve(type.typeArguments.single, elem);
    final annot = kBacklinkAnnotation.annotationsOfExact(elem).firstOrNull;
    final value = annot?.getField('name')?.toStringValue();
    if (value == null) {
      fail(
        'Backlinks must be annotated with `@Backlink(\'fieldName\')`.',
        elem,
      );
    }
    return BacklinksType(inner, value);
  }

  fail(
    'Unsupported field type `$type` (must be one of: `Atom`, `AtomOption`, '
    '`AtomDefault`, `Link`, `LinkOption`, `Multilinks` or `Backlinks`).',
    elem,
  );
}
```
