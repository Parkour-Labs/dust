// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetGraphDataCollection on Isar {
  IsarCollection<GraphData> get graphDatas => this.collection();
}

const GraphDataSchema = CollectionSchema(
  name: r'GraphData',
  id: -6879909815649973494,
  properties: {
    r'lastTimeStamp': PropertySchema(
      id: 0,
      name: r'lastTimeStamp',
      type: IsarType.long,
    ),
    r'replicaId': PropertySchema(
      id: 1,
      name: r'replicaId',
      type: IsarType.long,
    )
  },
  estimateSize: _graphDataEstimateSize,
  serialize: _graphDataSerialize,
  deserialize: _graphDataDeserialize,
  deserializeProp: _graphDataDeserializeProp,
  idName: r'graphId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _graphDataGetId,
  getLinks: _graphDataGetLinks,
  attach: _graphDataAttach,
  version: '3.0.5',
);

int _graphDataEstimateSize(
  GraphData object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _graphDataSerialize(
  GraphData object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.lastTimeStamp);
  writer.writeLong(offsets[1], object.replicaId);
}

GraphData _graphDataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GraphData();
  object.graphId = id;
  object.lastTimeStamp = reader.readLong(offsets[0]);
  object.replicaId = reader.readLong(offsets[1]);
  return object;
}

P _graphDataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _graphDataGetId(GraphData object) {
  return object.graphId;
}

List<IsarLinkBase<dynamic>> _graphDataGetLinks(GraphData object) {
  return [];
}

void _graphDataAttach(IsarCollection<dynamic> col, Id id, GraphData object) {
  object.graphId = id;
}

extension GraphDataQueryWhereSort
    on QueryBuilder<GraphData, GraphData, QWhere> {
  QueryBuilder<GraphData, GraphData, QAfterWhere> anyGraphId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GraphDataQueryWhere
    on QueryBuilder<GraphData, GraphData, QWhereClause> {
  QueryBuilder<GraphData, GraphData, QAfterWhereClause> graphIdEqualTo(
      Id graphId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: graphId,
        upper: graphId,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterWhereClause> graphIdNotEqualTo(
      Id graphId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: graphId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: graphId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: graphId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: graphId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterWhereClause> graphIdGreaterThan(
      Id graphId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: graphId, includeLower: include),
      );
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterWhereClause> graphIdLessThan(
      Id graphId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: graphId, includeUpper: include),
      );
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterWhereClause> graphIdBetween(
    Id lowerGraphId,
    Id upperGraphId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerGraphId,
        includeLower: includeLower,
        upper: upperGraphId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension GraphDataQueryFilter
    on QueryBuilder<GraphData, GraphData, QFilterCondition> {
  QueryBuilder<GraphData, GraphData, QAfterFilterCondition> graphIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'graphId',
        value: value,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition> graphIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'graphId',
        value: value,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition> graphIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'graphId',
        value: value,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition> graphIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'graphId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition>
      lastTimeStampEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastTimeStamp',
        value: value,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition>
      lastTimeStampGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastTimeStamp',
        value: value,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition>
      lastTimeStampLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastTimeStamp',
        value: value,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition>
      lastTimeStampBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastTimeStamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition> replicaIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replicaId',
        value: value,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition>
      replicaIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replicaId',
        value: value,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition> replicaIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replicaId',
        value: value,
      ));
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterFilterCondition> replicaIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replicaId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension GraphDataQueryObject
    on QueryBuilder<GraphData, GraphData, QFilterCondition> {}

extension GraphDataQueryLinks
    on QueryBuilder<GraphData, GraphData, QFilterCondition> {}

extension GraphDataQuerySortBy on QueryBuilder<GraphData, GraphData, QSortBy> {
  QueryBuilder<GraphData, GraphData, QAfterSortBy> sortByLastTimeStamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTimeStamp', Sort.asc);
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterSortBy> sortByLastTimeStampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTimeStamp', Sort.desc);
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterSortBy> sortByReplicaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.asc);
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterSortBy> sortByReplicaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.desc);
    });
  }
}

extension GraphDataQuerySortThenBy
    on QueryBuilder<GraphData, GraphData, QSortThenBy> {
  QueryBuilder<GraphData, GraphData, QAfterSortBy> thenByGraphId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.asc);
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterSortBy> thenByGraphIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.desc);
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterSortBy> thenByLastTimeStamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTimeStamp', Sort.asc);
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterSortBy> thenByLastTimeStampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTimeStamp', Sort.desc);
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterSortBy> thenByReplicaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.asc);
    });
  }

  QueryBuilder<GraphData, GraphData, QAfterSortBy> thenByReplicaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.desc);
    });
  }
}

extension GraphDataQueryWhereDistinct
    on QueryBuilder<GraphData, GraphData, QDistinct> {
  QueryBuilder<GraphData, GraphData, QDistinct> distinctByLastTimeStamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastTimeStamp');
    });
  }

  QueryBuilder<GraphData, GraphData, QDistinct> distinctByReplicaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replicaId');
    });
  }
}

extension GraphDataQueryProperty
    on QueryBuilder<GraphData, GraphData, QQueryProperty> {
  QueryBuilder<GraphData, int, QQueryOperations> graphIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'graphId');
    });
  }

  QueryBuilder<GraphData, int, QQueryOperations> lastTimeStampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastTimeStamp');
    });
  }

  QueryBuilder<GraphData, int, QQueryOperations> replicaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replicaId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetAtomOpCollection on Isar {
  IsarCollection<AtomOp> get atomOps => this.collection();
}

const AtomOpSchema = CollectionSchema(
  name: r'AtomOp',
  id: 8424236821393667586,
  properties: {
    r'atomId': PropertySchema(
      id: 0,
      name: r'atomId',
      type: IsarType.long,
    ),
    r'graphId': PropertySchema(
      id: 1,
      name: r'graphId',
      type: IsarType.long,
    ),
    r'label': PropertySchema(
      id: 2,
      name: r'label',
      type: IsarType.long,
    ),
    r'removed': PropertySchema(
      id: 3,
      name: r'removed',
      type: IsarType.bool,
    ),
    r'replicaId': PropertySchema(
      id: 4,
      name: r'replicaId',
      type: IsarType.long,
    ),
    r'srcId': PropertySchema(
      id: 5,
      name: r'srcId',
      type: IsarType.long,
    ),
    r'timeStamp': PropertySchema(
      id: 6,
      name: r'timeStamp',
      type: IsarType.long,
    ),
    r'value': PropertySchema(
      id: 7,
      name: r'value',
      type: IsarType.string,
    )
  },
  estimateSize: _atomOpEstimateSize,
  serialize: _atomOpSerialize,
  deserialize: _atomOpDeserialize,
  deserializeProp: _atomOpDeserializeProp,
  idName: r'opId',
  indexes: {
    r'graphId_atomId': IndexSchema(
      id: 190457333907287182,
      name: r'graphId_atomId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'graphId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'atomId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'graphId_srcId_label': IndexSchema(
      id: 3952538883331396612,
      name: r'graphId_srcId_label',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'graphId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'srcId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'label',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'graphId_value_label': IndexSchema(
      id: -3458080431141887644,
      name: r'graphId_value_label',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'graphId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'value',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'label',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _atomOpGetId,
  getLinks: _atomOpGetLinks,
  attach: _atomOpAttach,
  version: '3.0.5',
);

int _atomOpEstimateSize(
  AtomOp object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.value.length * 3;
  return bytesCount;
}

void _atomOpSerialize(
  AtomOp object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.atomId);
  writer.writeLong(offsets[1], object.graphId);
  writer.writeLong(offsets[2], object.label);
  writer.writeBool(offsets[3], object.removed);
  writer.writeLong(offsets[4], object.replicaId);
  writer.writeLong(offsets[5], object.srcId);
  writer.writeLong(offsets[6], object.timeStamp);
  writer.writeString(offsets[7], object.value);
}

AtomOp _atomOpDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AtomOp();
  object.atomId = reader.readLong(offsets[0]);
  object.graphId = reader.readLong(offsets[1]);
  object.label = reader.readLong(offsets[2]);
  object.opId = id;
  object.removed = reader.readBool(offsets[3]);
  object.replicaId = reader.readLong(offsets[4]);
  object.srcId = reader.readLong(offsets[5]);
  object.timeStamp = reader.readLong(offsets[6]);
  object.value = reader.readString(offsets[7]);
  return object;
}

P _atomOpDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _atomOpGetId(AtomOp object) {
  return object.opId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _atomOpGetLinks(AtomOp object) {
  return [];
}

void _atomOpAttach(IsarCollection<dynamic> col, Id id, AtomOp object) {
  object.opId = id;
}

extension AtomOpByIndex on IsarCollection<AtomOp> {
  Future<AtomOp?> getByGraphIdAtomId(int graphId, int atomId) {
    return getByIndex(r'graphId_atomId', [graphId, atomId]);
  }

  AtomOp? getByGraphIdAtomIdSync(int graphId, int atomId) {
    return getByIndexSync(r'graphId_atomId', [graphId, atomId]);
  }

  Future<bool> deleteByGraphIdAtomId(int graphId, int atomId) {
    return deleteByIndex(r'graphId_atomId', [graphId, atomId]);
  }

  bool deleteByGraphIdAtomIdSync(int graphId, int atomId) {
    return deleteByIndexSync(r'graphId_atomId', [graphId, atomId]);
  }

  Future<List<AtomOp?>> getAllByGraphIdAtomId(
      List<int> graphIdValues, List<int> atomIdValues) {
    final len = graphIdValues.length;
    assert(atomIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([graphIdValues[i], atomIdValues[i]]);
    }

    return getAllByIndex(r'graphId_atomId', values);
  }

  List<AtomOp?> getAllByGraphIdAtomIdSync(
      List<int> graphIdValues, List<int> atomIdValues) {
    final len = graphIdValues.length;
    assert(atomIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([graphIdValues[i], atomIdValues[i]]);
    }

    return getAllByIndexSync(r'graphId_atomId', values);
  }

  Future<int> deleteAllByGraphIdAtomId(
      List<int> graphIdValues, List<int> atomIdValues) {
    final len = graphIdValues.length;
    assert(atomIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([graphIdValues[i], atomIdValues[i]]);
    }

    return deleteAllByIndex(r'graphId_atomId', values);
  }

  int deleteAllByGraphIdAtomIdSync(
      List<int> graphIdValues, List<int> atomIdValues) {
    final len = graphIdValues.length;
    assert(atomIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([graphIdValues[i], atomIdValues[i]]);
    }

    return deleteAllByIndexSync(r'graphId_atomId', values);
  }

  Future<Id> putByGraphIdAtomId(AtomOp object) {
    return putByIndex(r'graphId_atomId', object);
  }

  Id putByGraphIdAtomIdSync(AtomOp object, {bool saveLinks = true}) {
    return putByIndexSync(r'graphId_atomId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByGraphIdAtomId(List<AtomOp> objects) {
    return putAllByIndex(r'graphId_atomId', objects);
  }

  List<Id> putAllByGraphIdAtomIdSync(List<AtomOp> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'graphId_atomId', objects, saveLinks: saveLinks);
  }
}

extension AtomOpQueryWhereSort on QueryBuilder<AtomOp, AtomOp, QWhere> {
  QueryBuilder<AtomOp, AtomOp, QAfterWhere> anyOpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhere> anyGraphIdAtomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'graphId_atomId'),
      );
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhere> anyGraphIdSrcIdLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'graphId_srcId_label'),
      );
    });
  }
}

extension AtomOpQueryWhere on QueryBuilder<AtomOp, AtomOp, QWhereClause> {
  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> opIdEqualTo(Id opId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: opId,
        upper: opId,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> opIdNotEqualTo(Id opId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: opId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: opId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: opId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: opId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> opIdGreaterThan(Id opId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: opId, includeLower: include),
      );
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> opIdLessThan(Id opId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: opId, includeUpper: include),
      );
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> opIdBetween(
    Id lowerOpId,
    Id upperOpId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerOpId,
        includeLower: includeLower,
        upper: upperOpId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdEqualToAnyAtomId(
      int graphId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_atomId',
        value: [graphId],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdNotEqualToAnyAtomId(
      int graphId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_atomId',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_atomId',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_atomId',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_atomId',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdGreaterThanAnyAtomId(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_atomId',
        lower: [graphId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdLessThanAnyAtomId(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_atomId',
        lower: [],
        upper: [graphId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdBetweenAnyAtomId(
    int lowerGraphId,
    int upperGraphId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_atomId',
        lower: [lowerGraphId],
        includeLower: includeLower,
        upper: [upperGraphId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdAtomIdEqualTo(
      int graphId, int atomId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_atomId',
        value: [graphId, atomId],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdEqualToAtomIdNotEqualTo(int graphId, int atomId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_atomId',
              lower: [graphId],
              upper: [graphId, atomId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_atomId',
              lower: [graphId, atomId],
              includeLower: false,
              upper: [graphId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_atomId',
              lower: [graphId, atomId],
              includeLower: false,
              upper: [graphId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_atomId',
              lower: [graphId],
              upper: [graphId, atomId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdEqualToAtomIdGreaterThan(
    int graphId,
    int atomId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_atomId',
        lower: [graphId, atomId],
        includeLower: include,
        upper: [graphId],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdEqualToAtomIdLessThan(
    int graphId,
    int atomId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_atomId',
        lower: [graphId],
        upper: [graphId, atomId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdEqualToAtomIdBetween(
    int graphId,
    int lowerAtomId,
    int upperAtomId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_atomId',
        lower: [graphId, lowerAtomId],
        includeLower: includeLower,
        upper: [graphId, upperAtomId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdEqualToAnySrcIdLabel(
      int graphId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_srcId_label',
        value: [graphId],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdNotEqualToAnySrcIdLabel(int graphId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdGreaterThanAnySrcIdLabel(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdLessThanAnySrcIdLabel(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [],
        upper: [graphId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdBetweenAnySrcIdLabel(
    int lowerGraphId,
    int upperGraphId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [lowerGraphId],
        includeLower: includeLower,
        upper: [upperGraphId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdSrcIdEqualToAnyLabel(
      int graphId, int srcId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_srcId_label',
        value: [graphId, srcId],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdEqualToSrcIdNotEqualToAnyLabel(int graphId, int srcId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId],
              upper: [graphId, srcId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId],
              includeLower: false,
              upper: [graphId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId],
              includeLower: false,
              upper: [graphId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId],
              upper: [graphId, srcId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdEqualToSrcIdGreaterThanAnyLabel(
    int graphId,
    int srcId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, srcId],
        includeLower: include,
        upper: [graphId],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdEqualToSrcIdLessThanAnyLabel(
    int graphId,
    int srcId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId],
        upper: [graphId, srcId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdEqualToSrcIdBetweenAnyLabel(
    int graphId,
    int lowerSrcId,
    int upperSrcId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, lowerSrcId],
        includeLower: includeLower,
        upper: [graphId, upperSrcId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdSrcIdLabelEqualTo(
      int graphId, int srcId, int label) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_srcId_label',
        value: [graphId, srcId, label],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdSrcIdEqualToLabelNotEqualTo(int graphId, int srcId, int label) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId],
              upper: [graphId, srcId, label],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId, label],
              includeLower: false,
              upper: [graphId, srcId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId, label],
              includeLower: false,
              upper: [graphId, srcId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId],
              upper: [graphId, srcId, label],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdSrcIdEqualToLabelGreaterThan(
    int graphId,
    int srcId,
    int label, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, srcId, label],
        includeLower: include,
        upper: [graphId, srcId],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdSrcIdEqualToLabelLessThan(
    int graphId,
    int srcId,
    int label, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, srcId],
        upper: [graphId, srcId, label],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdSrcIdEqualToLabelBetween(
    int graphId,
    int srcId,
    int lowerLabel,
    int upperLabel, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, srcId, lowerLabel],
        includeLower: includeLower,
        upper: [graphId, srcId, upperLabel],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdEqualToAnyValueLabel(
      int graphId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_value_label',
        value: [graphId],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdNotEqualToAnyValueLabel(int graphId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdGreaterThanAnyValueLabel(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_value_label',
        lower: [graphId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdLessThanAnyValueLabel(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_value_label',
        lower: [],
        upper: [graphId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdBetweenAnyValueLabel(
    int lowerGraphId,
    int upperGraphId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_value_label',
        lower: [lowerGraphId],
        includeLower: includeLower,
        upper: [upperGraphId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdValueEqualToAnyLabel(
      int graphId, String value) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_value_label',
        value: [graphId, value],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdEqualToValueNotEqualToAnyLabel(int graphId, String value) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId],
              upper: [graphId, value],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId, value],
              includeLower: false,
              upper: [graphId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId, value],
              includeLower: false,
              upper: [graphId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId],
              upper: [graphId, value],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause> graphIdValueLabelEqualTo(
      int graphId, String value, int label) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_value_label',
        value: [graphId, value, label],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdValueEqualToLabelNotEqualTo(int graphId, String value, int label) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId, value],
              upper: [graphId, value, label],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId, value, label],
              includeLower: false,
              upper: [graphId, value],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId, value, label],
              includeLower: false,
              upper: [graphId, value],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_value_label',
              lower: [graphId, value],
              upper: [graphId, value, label],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdValueEqualToLabelGreaterThan(
    int graphId,
    String value,
    int label, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_value_label',
        lower: [graphId, value, label],
        includeLower: include,
        upper: [graphId, value],
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdValueEqualToLabelLessThan(
    int graphId,
    String value,
    int label, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_value_label',
        lower: [graphId, value],
        upper: [graphId, value, label],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterWhereClause>
      graphIdValueEqualToLabelBetween(
    int graphId,
    String value,
    int lowerLabel,
    int upperLabel, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_value_label',
        lower: [graphId, value, lowerLabel],
        includeLower: includeLower,
        upper: [graphId, value, upperLabel],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AtomOpQueryFilter on QueryBuilder<AtomOp, AtomOp, QFilterCondition> {
  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> atomIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'atomId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> atomIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'atomId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> atomIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'atomId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> atomIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'atomId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> graphIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'graphId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> graphIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'graphId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> graphIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'graphId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> graphIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'graphId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> labelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> labelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'label',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> labelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'label',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> labelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'label',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> opIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'opId',
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> opIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'opId',
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> opIdEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'opId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> opIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'opId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> opIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'opId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> opIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'opId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> removedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'removed',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> replicaIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replicaId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> replicaIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replicaId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> replicaIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replicaId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> replicaIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replicaId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> srcIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'srcId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> srcIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'srcId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> srcIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'srcId',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> srcIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'srcId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> timeStampEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeStamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> timeStampGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeStamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> timeStampLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeStamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> timeStampBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeStamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'value',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'value',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'value',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'value',
        value: '',
      ));
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterFilterCondition> valueIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'value',
        value: '',
      ));
    });
  }
}

extension AtomOpQueryObject on QueryBuilder<AtomOp, AtomOp, QFilterCondition> {}

extension AtomOpQueryLinks on QueryBuilder<AtomOp, AtomOp, QFilterCondition> {}

extension AtomOpQuerySortBy on QueryBuilder<AtomOp, AtomOp, QSortBy> {
  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByAtomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'atomId', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByAtomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'atomId', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByGraphId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByGraphIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByRemoved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removed', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByRemovedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removed', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByReplicaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByReplicaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortBySrcId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srcId', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortBySrcIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srcId', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByTimeStamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeStamp', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByTimeStampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeStamp', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension AtomOpQuerySortThenBy on QueryBuilder<AtomOp, AtomOp, QSortThenBy> {
  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByAtomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'atomId', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByAtomIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'atomId', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByGraphId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByGraphIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByOpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opId', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByOpIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opId', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByRemoved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removed', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByRemovedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removed', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByReplicaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByReplicaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenBySrcId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srcId', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenBySrcIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srcId', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByTimeStamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeStamp', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByTimeStampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeStamp', Sort.desc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<AtomOp, AtomOp, QAfterSortBy> thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension AtomOpQueryWhereDistinct on QueryBuilder<AtomOp, AtomOp, QDistinct> {
  QueryBuilder<AtomOp, AtomOp, QDistinct> distinctByAtomId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'atomId');
    });
  }

  QueryBuilder<AtomOp, AtomOp, QDistinct> distinctByGraphId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'graphId');
    });
  }

  QueryBuilder<AtomOp, AtomOp, QDistinct> distinctByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'label');
    });
  }

  QueryBuilder<AtomOp, AtomOp, QDistinct> distinctByRemoved() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'removed');
    });
  }

  QueryBuilder<AtomOp, AtomOp, QDistinct> distinctByReplicaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replicaId');
    });
  }

  QueryBuilder<AtomOp, AtomOp, QDistinct> distinctBySrcId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'srcId');
    });
  }

  QueryBuilder<AtomOp, AtomOp, QDistinct> distinctByTimeStamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeStamp');
    });
  }

  QueryBuilder<AtomOp, AtomOp, QDistinct> distinctByValue(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value', caseSensitive: caseSensitive);
    });
  }
}

extension AtomOpQueryProperty on QueryBuilder<AtomOp, AtomOp, QQueryProperty> {
  QueryBuilder<AtomOp, int, QQueryOperations> opIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'opId');
    });
  }

  QueryBuilder<AtomOp, int, QQueryOperations> atomIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'atomId');
    });
  }

  QueryBuilder<AtomOp, int, QQueryOperations> graphIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'graphId');
    });
  }

  QueryBuilder<AtomOp, int, QQueryOperations> labelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'label');
    });
  }

  QueryBuilder<AtomOp, bool, QQueryOperations> removedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'removed');
    });
  }

  QueryBuilder<AtomOp, int, QQueryOperations> replicaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replicaId');
    });
  }

  QueryBuilder<AtomOp, int, QQueryOperations> srcIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'srcId');
    });
  }

  QueryBuilder<AtomOp, int, QQueryOperations> timeStampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeStamp');
    });
  }

  QueryBuilder<AtomOp, String, QQueryOperations> valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters

extension GetEdgeOpCollection on Isar {
  IsarCollection<EdgeOp> get edgeOps => this.collection();
}

const EdgeOpSchema = CollectionSchema(
  name: r'EdgeOp',
  id: 3271032587452033770,
  properties: {
    r'dstId': PropertySchema(
      id: 0,
      name: r'dstId',
      type: IsarType.long,
    ),
    r'edgeId': PropertySchema(
      id: 1,
      name: r'edgeId',
      type: IsarType.long,
    ),
    r'graphId': PropertySchema(
      id: 2,
      name: r'graphId',
      type: IsarType.long,
    ),
    r'label': PropertySchema(
      id: 3,
      name: r'label',
      type: IsarType.long,
    ),
    r'removed': PropertySchema(
      id: 4,
      name: r'removed',
      type: IsarType.bool,
    ),
    r'replicaId': PropertySchema(
      id: 5,
      name: r'replicaId',
      type: IsarType.long,
    ),
    r'srcId': PropertySchema(
      id: 6,
      name: r'srcId',
      type: IsarType.long,
    ),
    r'timeStamp': PropertySchema(
      id: 7,
      name: r'timeStamp',
      type: IsarType.long,
    )
  },
  estimateSize: _edgeOpEstimateSize,
  serialize: _edgeOpSerialize,
  deserialize: _edgeOpDeserialize,
  deserializeProp: _edgeOpDeserializeProp,
  idName: r'opId',
  indexes: {
    r'graphId_edgeId': IndexSchema(
      id: 2979891312642430158,
      name: r'graphId_edgeId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'graphId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'edgeId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'graphId_srcId_label': IndexSchema(
      id: 3952538883331396612,
      name: r'graphId_srcId_label',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'graphId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'srcId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'label',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'graphId_dstId_label': IndexSchema(
      id: 438363305955138386,
      name: r'graphId_dstId_label',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'graphId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'dstId',
          type: IndexType.value,
          caseSensitive: false,
        ),
        IndexPropertySchema(
          name: r'label',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _edgeOpGetId,
  getLinks: _edgeOpGetLinks,
  attach: _edgeOpAttach,
  version: '3.0.5',
);

int _edgeOpEstimateSize(
  EdgeOp object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _edgeOpSerialize(
  EdgeOp object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.dstId);
  writer.writeLong(offsets[1], object.edgeId);
  writer.writeLong(offsets[2], object.graphId);
  writer.writeLong(offsets[3], object.label);
  writer.writeBool(offsets[4], object.removed);
  writer.writeLong(offsets[5], object.replicaId);
  writer.writeLong(offsets[6], object.srcId);
  writer.writeLong(offsets[7], object.timeStamp);
}

EdgeOp _edgeOpDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EdgeOp();
  object.dstId = reader.readLong(offsets[0]);
  object.edgeId = reader.readLong(offsets[1]);
  object.graphId = reader.readLong(offsets[2]);
  object.label = reader.readLong(offsets[3]);
  object.opId = id;
  object.removed = reader.readBool(offsets[4]);
  object.replicaId = reader.readLong(offsets[5]);
  object.srcId = reader.readLong(offsets[6]);
  object.timeStamp = reader.readLong(offsets[7]);
  return object;
}

P _edgeOpDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _edgeOpGetId(EdgeOp object) {
  return object.opId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _edgeOpGetLinks(EdgeOp object) {
  return [];
}

void _edgeOpAttach(IsarCollection<dynamic> col, Id id, EdgeOp object) {
  object.opId = id;
}

extension EdgeOpByIndex on IsarCollection<EdgeOp> {
  Future<EdgeOp?> getByGraphIdEdgeId(int graphId, int edgeId) {
    return getByIndex(r'graphId_edgeId', [graphId, edgeId]);
  }

  EdgeOp? getByGraphIdEdgeIdSync(int graphId, int edgeId) {
    return getByIndexSync(r'graphId_edgeId', [graphId, edgeId]);
  }

  Future<bool> deleteByGraphIdEdgeId(int graphId, int edgeId) {
    return deleteByIndex(r'graphId_edgeId', [graphId, edgeId]);
  }

  bool deleteByGraphIdEdgeIdSync(int graphId, int edgeId) {
    return deleteByIndexSync(r'graphId_edgeId', [graphId, edgeId]);
  }

  Future<List<EdgeOp?>> getAllByGraphIdEdgeId(
      List<int> graphIdValues, List<int> edgeIdValues) {
    final len = graphIdValues.length;
    assert(edgeIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([graphIdValues[i], edgeIdValues[i]]);
    }

    return getAllByIndex(r'graphId_edgeId', values);
  }

  List<EdgeOp?> getAllByGraphIdEdgeIdSync(
      List<int> graphIdValues, List<int> edgeIdValues) {
    final len = graphIdValues.length;
    assert(edgeIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([graphIdValues[i], edgeIdValues[i]]);
    }

    return getAllByIndexSync(r'graphId_edgeId', values);
  }

  Future<int> deleteAllByGraphIdEdgeId(
      List<int> graphIdValues, List<int> edgeIdValues) {
    final len = graphIdValues.length;
    assert(edgeIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([graphIdValues[i], edgeIdValues[i]]);
    }

    return deleteAllByIndex(r'graphId_edgeId', values);
  }

  int deleteAllByGraphIdEdgeIdSync(
      List<int> graphIdValues, List<int> edgeIdValues) {
    final len = graphIdValues.length;
    assert(edgeIdValues.length == len,
        'All index values must have the same length');
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([graphIdValues[i], edgeIdValues[i]]);
    }

    return deleteAllByIndexSync(r'graphId_edgeId', values);
  }

  Future<Id> putByGraphIdEdgeId(EdgeOp object) {
    return putByIndex(r'graphId_edgeId', object);
  }

  Id putByGraphIdEdgeIdSync(EdgeOp object, {bool saveLinks = true}) {
    return putByIndexSync(r'graphId_edgeId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByGraphIdEdgeId(List<EdgeOp> objects) {
    return putAllByIndex(r'graphId_edgeId', objects);
  }

  List<Id> putAllByGraphIdEdgeIdSync(List<EdgeOp> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'graphId_edgeId', objects, saveLinks: saveLinks);
  }
}

extension EdgeOpQueryWhereSort on QueryBuilder<EdgeOp, EdgeOp, QWhere> {
  QueryBuilder<EdgeOp, EdgeOp, QAfterWhere> anyOpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhere> anyGraphIdEdgeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'graphId_edgeId'),
      );
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhere> anyGraphIdSrcIdLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'graphId_srcId_label'),
      );
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhere> anyGraphIdDstIdLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'graphId_dstId_label'),
      );
    });
  }
}

extension EdgeOpQueryWhere on QueryBuilder<EdgeOp, EdgeOp, QWhereClause> {
  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> opIdEqualTo(Id opId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: opId,
        upper: opId,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> opIdNotEqualTo(Id opId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: opId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: opId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: opId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: opId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> opIdGreaterThan(Id opId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: opId, includeLower: include),
      );
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> opIdLessThan(Id opId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: opId, includeUpper: include),
      );
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> opIdBetween(
    Id lowerOpId,
    Id upperOpId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerOpId,
        includeLower: includeLower,
        upper: upperOpId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdEqualToAnyEdgeId(
      int graphId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_edgeId',
        value: [graphId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdNotEqualToAnyEdgeId(
      int graphId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_edgeId',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_edgeId',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_edgeId',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_edgeId',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdGreaterThanAnyEdgeId(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_edgeId',
        lower: [graphId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdLessThanAnyEdgeId(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_edgeId',
        lower: [],
        upper: [graphId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdBetweenAnyEdgeId(
    int lowerGraphId,
    int upperGraphId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_edgeId',
        lower: [lowerGraphId],
        includeLower: includeLower,
        upper: [upperGraphId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdEdgeIdEqualTo(
      int graphId, int edgeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_edgeId',
        value: [graphId, edgeId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToEdgeIdNotEqualTo(int graphId, int edgeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_edgeId',
              lower: [graphId],
              upper: [graphId, edgeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_edgeId',
              lower: [graphId, edgeId],
              includeLower: false,
              upper: [graphId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_edgeId',
              lower: [graphId, edgeId],
              includeLower: false,
              upper: [graphId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_edgeId',
              lower: [graphId],
              upper: [graphId, edgeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToEdgeIdGreaterThan(
    int graphId,
    int edgeId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_edgeId',
        lower: [graphId, edgeId],
        includeLower: include,
        upper: [graphId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdEqualToEdgeIdLessThan(
    int graphId,
    int edgeId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_edgeId',
        lower: [graphId],
        upper: [graphId, edgeId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdEqualToEdgeIdBetween(
    int graphId,
    int lowerEdgeId,
    int upperEdgeId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_edgeId',
        lower: [graphId, lowerEdgeId],
        includeLower: includeLower,
        upper: [graphId, upperEdgeId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdEqualToAnySrcIdLabel(
      int graphId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_srcId_label',
        value: [graphId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdNotEqualToAnySrcIdLabel(int graphId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdGreaterThanAnySrcIdLabel(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdLessThanAnySrcIdLabel(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [],
        upper: [graphId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdBetweenAnySrcIdLabel(
    int lowerGraphId,
    int upperGraphId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [lowerGraphId],
        includeLower: includeLower,
        upper: [upperGraphId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdSrcIdEqualToAnyLabel(
      int graphId, int srcId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_srcId_label',
        value: [graphId, srcId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToSrcIdNotEqualToAnyLabel(int graphId, int srcId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId],
              upper: [graphId, srcId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId],
              includeLower: false,
              upper: [graphId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId],
              includeLower: false,
              upper: [graphId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId],
              upper: [graphId, srcId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToSrcIdGreaterThanAnyLabel(
    int graphId,
    int srcId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, srcId],
        includeLower: include,
        upper: [graphId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToSrcIdLessThanAnyLabel(
    int graphId,
    int srcId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId],
        upper: [graphId, srcId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToSrcIdBetweenAnyLabel(
    int graphId,
    int lowerSrcId,
    int upperSrcId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, lowerSrcId],
        includeLower: includeLower,
        upper: [graphId, upperSrcId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdSrcIdLabelEqualTo(
      int graphId, int srcId, int label) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_srcId_label',
        value: [graphId, srcId, label],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdSrcIdEqualToLabelNotEqualTo(int graphId, int srcId, int label) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId],
              upper: [graphId, srcId, label],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId, label],
              includeLower: false,
              upper: [graphId, srcId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId, label],
              includeLower: false,
              upper: [graphId, srcId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_srcId_label',
              lower: [graphId, srcId],
              upper: [graphId, srcId, label],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdSrcIdEqualToLabelGreaterThan(
    int graphId,
    int srcId,
    int label, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, srcId, label],
        includeLower: include,
        upper: [graphId, srcId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdSrcIdEqualToLabelLessThan(
    int graphId,
    int srcId,
    int label, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, srcId],
        upper: [graphId, srcId, label],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdSrcIdEqualToLabelBetween(
    int graphId,
    int srcId,
    int lowerLabel,
    int upperLabel, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_srcId_label',
        lower: [graphId, srcId, lowerLabel],
        includeLower: includeLower,
        upper: [graphId, srcId, upperLabel],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdEqualToAnyDstIdLabel(
      int graphId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_dstId_label',
        value: [graphId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdNotEqualToAnyDstIdLabel(int graphId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [],
              upper: [graphId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdGreaterThanAnyDstIdLabel(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_dstId_label',
        lower: [graphId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdLessThanAnyDstIdLabel(
    int graphId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_dstId_label',
        lower: [],
        upper: [graphId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdBetweenAnyDstIdLabel(
    int lowerGraphId,
    int upperGraphId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_dstId_label',
        lower: [lowerGraphId],
        includeLower: includeLower,
        upper: [upperGraphId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdDstIdEqualToAnyLabel(
      int graphId, int dstId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_dstId_label',
        value: [graphId, dstId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToDstIdNotEqualToAnyLabel(int graphId, int dstId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId],
              upper: [graphId, dstId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId, dstId],
              includeLower: false,
              upper: [graphId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId, dstId],
              includeLower: false,
              upper: [graphId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId],
              upper: [graphId, dstId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToDstIdGreaterThanAnyLabel(
    int graphId,
    int dstId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_dstId_label',
        lower: [graphId, dstId],
        includeLower: include,
        upper: [graphId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToDstIdLessThanAnyLabel(
    int graphId,
    int dstId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_dstId_label',
        lower: [graphId],
        upper: [graphId, dstId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdEqualToDstIdBetweenAnyLabel(
    int graphId,
    int lowerDstId,
    int upperDstId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_dstId_label',
        lower: [graphId, lowerDstId],
        includeLower: includeLower,
        upper: [graphId, upperDstId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause> graphIdDstIdLabelEqualTo(
      int graphId, int dstId, int label) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'graphId_dstId_label',
        value: [graphId, dstId, label],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdDstIdEqualToLabelNotEqualTo(int graphId, int dstId, int label) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId, dstId],
              upper: [graphId, dstId, label],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId, dstId, label],
              includeLower: false,
              upper: [graphId, dstId],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId, dstId, label],
              includeLower: false,
              upper: [graphId, dstId],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'graphId_dstId_label',
              lower: [graphId, dstId],
              upper: [graphId, dstId, label],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdDstIdEqualToLabelGreaterThan(
    int graphId,
    int dstId,
    int label, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_dstId_label',
        lower: [graphId, dstId, label],
        includeLower: include,
        upper: [graphId, dstId],
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdDstIdEqualToLabelLessThan(
    int graphId,
    int dstId,
    int label, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_dstId_label',
        lower: [graphId, dstId],
        upper: [graphId, dstId, label],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterWhereClause>
      graphIdDstIdEqualToLabelBetween(
    int graphId,
    int dstId,
    int lowerLabel,
    int upperLabel, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'graphId_dstId_label',
        lower: [graphId, dstId, lowerLabel],
        includeLower: includeLower,
        upper: [graphId, dstId, upperLabel],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EdgeOpQueryFilter on QueryBuilder<EdgeOp, EdgeOp, QFilterCondition> {
  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> dstIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dstId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> dstIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dstId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> dstIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dstId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> dstIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dstId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> edgeIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'edgeId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> edgeIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'edgeId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> edgeIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'edgeId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> edgeIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'edgeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> graphIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'graphId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> graphIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'graphId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> graphIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'graphId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> graphIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'graphId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> labelEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> labelGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'label',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> labelLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'label',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> labelBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'label',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> opIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'opId',
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> opIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'opId',
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> opIdEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'opId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> opIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'opId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> opIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'opId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> opIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'opId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> removedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'removed',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> replicaIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'replicaId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> replicaIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'replicaId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> replicaIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'replicaId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> replicaIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'replicaId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> srcIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'srcId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> srcIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'srcId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> srcIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'srcId',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> srcIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'srcId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> timeStampEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeStamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> timeStampGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeStamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> timeStampLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeStamp',
        value: value,
      ));
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterFilterCondition> timeStampBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeStamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EdgeOpQueryObject on QueryBuilder<EdgeOp, EdgeOp, QFilterCondition> {}

extension EdgeOpQueryLinks on QueryBuilder<EdgeOp, EdgeOp, QFilterCondition> {}

extension EdgeOpQuerySortBy on QueryBuilder<EdgeOp, EdgeOp, QSortBy> {
  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByDstId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dstId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByDstIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dstId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByEdgeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edgeId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByEdgeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edgeId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByGraphId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByGraphIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByRemoved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removed', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByRemovedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removed', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByReplicaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByReplicaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortBySrcId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srcId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortBySrcIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srcId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByTimeStamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeStamp', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> sortByTimeStampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeStamp', Sort.desc);
    });
  }
}

extension EdgeOpQuerySortThenBy on QueryBuilder<EdgeOp, EdgeOp, QSortThenBy> {
  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByDstId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dstId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByDstIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dstId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByEdgeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edgeId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByEdgeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'edgeId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByGraphId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByGraphIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'graphId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'label', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByOpId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByOpIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByRemoved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removed', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByRemovedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'removed', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByReplicaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByReplicaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replicaId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenBySrcId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srcId', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenBySrcIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'srcId', Sort.desc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByTimeStamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeStamp', Sort.asc);
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QAfterSortBy> thenByTimeStampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeStamp', Sort.desc);
    });
  }
}

extension EdgeOpQueryWhereDistinct on QueryBuilder<EdgeOp, EdgeOp, QDistinct> {
  QueryBuilder<EdgeOp, EdgeOp, QDistinct> distinctByDstId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dstId');
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QDistinct> distinctByEdgeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'edgeId');
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QDistinct> distinctByGraphId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'graphId');
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QDistinct> distinctByLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'label');
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QDistinct> distinctByRemoved() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'removed');
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QDistinct> distinctByReplicaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'replicaId');
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QDistinct> distinctBySrcId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'srcId');
    });
  }

  QueryBuilder<EdgeOp, EdgeOp, QDistinct> distinctByTimeStamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeStamp');
    });
  }
}

extension EdgeOpQueryProperty on QueryBuilder<EdgeOp, EdgeOp, QQueryProperty> {
  QueryBuilder<EdgeOp, int, QQueryOperations> opIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'opId');
    });
  }

  QueryBuilder<EdgeOp, int, QQueryOperations> dstIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dstId');
    });
  }

  QueryBuilder<EdgeOp, int, QQueryOperations> edgeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'edgeId');
    });
  }

  QueryBuilder<EdgeOp, int, QQueryOperations> graphIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'graphId');
    });
  }

  QueryBuilder<EdgeOp, int, QQueryOperations> labelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'label');
    });
  }

  QueryBuilder<EdgeOp, bool, QQueryOperations> removedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'removed');
    });
  }

  QueryBuilder<EdgeOp, int, QQueryOperations> replicaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replicaId');
    });
  }

  QueryBuilder<EdgeOp, int, QQueryOperations> srcIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'srcId');
    });
  }

  QueryBuilder<EdgeOp, int, QQueryOperations> timeStampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeStamp');
    });
  }
}
