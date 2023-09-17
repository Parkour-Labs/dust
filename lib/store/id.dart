import '../ffi/native_structs.dart';

final class Id {
  final int high;
  final int low;

  const Id(this.high, this.low);

  Id.fromNative(CId cid)
      : high = cid.high,
        low = cid.low;

  @override
  bool operator ==(Object other) =>
      other is Id && other.high == high && other.low == low;

  @override
  int get hashCode => high ^ low;

  /// This is used for generating a deterministic, unique ID for unique atoms/links.
  /// Since both entity ID and label are random, a simple bitwise XOR would suffice.
  Id operator ^(int rhs) => Id(high, low ^ rhs);

  @override
  String toString() {
    return "${high.toRadixString(16)}${low.toRadixString(16)}";
  }
}
