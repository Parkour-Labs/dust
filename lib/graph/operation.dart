import 'dart:math';

import 'package:isar/isar.dart';

part 'operation.g.dart';

/*
/// 128-bit unique identifier.
@immutable
class Identifier extends Pair<int, int> {
  static final Random _random = Random.secure();

  const Identifier(super.first, super.second);

  factory Identifier.random() {
    final low = (_random.nextInt(1 << 32) << 32) + _random.nextInt(1 << 32);
    final high = (_random.nextInt(1 << 32) << 32) + _random.nextInt(1 << 32);
    return Identifier(low, high);
  }

  /// Lower 64 bits.
  int get low => first;

  /// Upper 64 bits.
  int get high => second;
}
*/

/// 64-bit is already enough for our purpose! Collision is not disastrous either.
/// See: https://lemire.me/blog/2019/12/12/are-64-bit-random-identifiers-free-from-collision/
class Identifier {
  static final Random _random = Random.secure();
  static int random() => (_random.nextInt(1 << 32) << 32) + _random.nextInt(1 << 32);
}

/// Graph metadata.
@Collection()
class GraphData {
  late final Id graphId;
  late final int replicaId;
  late int lastTimeStamp;

  GraphData();
  GraphData.values(this.graphId, this.replicaId, this.lastTimeStamp);
}

/// Atom operation (timestamped modification).
@Collection()
class AtomOp implements Comparable<AtomOp> {
  Id? opId;

  @Index(composite: [CompositeIndex('atomId')])
  @Index(composite: [CompositeIndex('srcId'), CompositeIndex('label')])
  @Index(composite: [CompositeIndex('value'), CompositeIndex('label')])
  late final int graphId;

  late final int timeStamp;
  late final int replicaId;

  late final int atomId;
  late final int label;
  late final int srcId;
  late final String value;
  late final bool removed;

  AtomOp();
  AtomOp.values(this.opId, this.graphId, this.timeStamp, this.replicaId, this.atomId, this.label, this.srcId,
      this.value, this.removed);

  /// `this` should override `other` iff `this.compareTo(other) > 0`.
  @override
  int compareTo(AtomOp other) {
    if (timeStamp != other.timeStamp) return timeStamp > other.timeStamp ? 1 : -1;
    if (replicaId != other.replicaId) return replicaId > other.replicaId ? 1 : -1;
    assert(identical(this, other) || opId! == other.opId!, 'Ties are impossible.');
    return 0;
  }
}

/// Edge operation (timestamped modification).
@Collection()
class EdgeOp implements Comparable<EdgeOp> {
  Id? opId;

  @Index(composite: [CompositeIndex('edgeId')])
  @Index(composite: [CompositeIndex('srcId'), CompositeIndex('label')])
  @Index(composite: [CompositeIndex('dstId'), CompositeIndex('label')])
  late final int graphId;

  late final int timeStamp;
  late final int replicaId;

  late final int edgeId;
  late final int label;
  late final int srcId;
  late final int dstId;
  late final bool removed;

  EdgeOp();
  EdgeOp.values(this.opId, this.graphId, this.timeStamp, this.replicaId, this.edgeId, this.label, this.srcId,
      this.dstId, this.removed);

  /// `this` should override `other` iff `this.compareTo(other) > 0`.
  @override
  int compareTo(EdgeOp other) {
    if (timeStamp != other.timeStamp) return timeStamp > other.timeStamp ? 1 : -1;
    if (replicaId != other.replicaId) return replicaId > other.replicaId ? 1 : -1;
    assert(identical(this, other) || opId! == other.opId!, 'Ties are impossible.');
    return 0;
  }
}
