part of 'store.dart';

final class Id {
  final int high;
  final int low;

  const Id(this.high, this.low);

  Id.fromNative(CId cid)
      : high = cid.high,
        low = cid.low;

  @override
  bool operator ==(Object other) => other is Id && other.high == high && other.low == low;

  @override
  int get hashCode => high ^ low;

  @override
  String toString() => hashCode.toString();
}
