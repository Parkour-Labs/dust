import 'joinable.dart';
import 'joinable_register.dart';

/// A last-writer-win graph.
class JoinableGraph<IV, IE, V, E> {
  final (Map<IV, JoinableRegister<V?>>, Map<IE, JoinableRegister<(IV, IV, E)?>>) data;

  JoinableGraph(this.data);

  /// [JoinableGraph] is an instance of [Joinable].
  static Joinable<JoinableGraph<IV, IE, V, E>, (Map<IV, JoinableRegister<V?>>, Map<IE, JoinableRegister<(IV, IV, E)?>>)>
      instJoinable<IV, IE, V, E>(TotalOrderMin<V?> ov, TotalOrderMin<(IV, IV, E)?> oe) {
    final base = Joinable.prod(
      Joinable.pi<IV, JoinableRegister<V?>, JoinableRegister<V?>>(
        JoinableRegister.instJoinable(ov),
        JoinableRegister.instTotalOrderMin(ov).min,
      ),
      Joinable.pi<IE, JoinableRegister<(IV, IV, E)?>, JoinableRegister<(IV, IV, E)?>>(
        JoinableRegister.instJoinable(oe),
        JoinableRegister.instTotalOrderMin(oe).min,
      ),
    );
    return Joinable(
      apply: (s, a) => JoinableGraph(base.apply(s.data, a)),
      id: base.id,
      comp: base.comp,
      le: (s, t) => base.le(s.data, t.data),
      join: (s, t) => JoinableGraph(base.join(s.data, t.data)),
    );
  }

  /// [JoinableGraph] is an instance of [DeltaJoinable].
  static DeltaJoinable<JoinableGraph<IV, IE, V, E>,
          (Map<IV, JoinableRegister<V?>>, Map<IE, JoinableRegister<(IV, IV, E)?>>)>
      instDeltaJoinable<IV, IE, V, E>(TotalOrderMin<V?> ov, TotalOrderMin<(IV, IV, E)?> oe) {
    final base = DeltaJoinable.prod(
      DeltaJoinable.pi<IV, JoinableRegister<V?>, JoinableRegister<V?>>(
        JoinableRegister.instDeltaJoinable(ov),
        JoinableRegister.instTotalOrderMin(ov).min,
      ),
      DeltaJoinable.pi<IE, JoinableRegister<(IV, IV, E)?>, JoinableRegister<(IV, IV, E)?>>(
        JoinableRegister.instDeltaJoinable(oe),
        JoinableRegister.instTotalOrderMin(oe).min,
      ),
    );
    return DeltaJoinable(
      apply: (s, a) => JoinableGraph(base.apply(s.data, a)),
      id: base.id,
      comp: base.comp,
      le: (s, t) => base.le(s.data, t.data),
      join: (s, t) => JoinableGraph(base.join(s.data, t.data)),
      deltaJoin: (s, a, b) => JoinableGraph(base.deltaJoin(s.data, a, b)),
    );
  }

  /// [JoinableGraph] is an instance of [GammaJoinable].
  static GammaJoinable<JoinableGraph<IV, IE, V, E>,
          (Map<IV, JoinableRegister<V?>>, Map<IE, JoinableRegister<(IV, IV, E)?>>)>
      instGammaJoinable<IV, IE, V, E>(TotalOrderMin<V?> ov, TotalOrderMin<(IV, IV, E)?> oe) {
    final base = GammaJoinable.prod(
      GammaJoinable.pi<IV, JoinableRegister<V?>, JoinableRegister<V?>>(
        JoinableRegister.instGammaJoinable(ov),
        JoinableRegister.instTotalOrderMin(ov).min,
      ),
      GammaJoinable.pi<IE, JoinableRegister<(IV, IV, E)?>, JoinableRegister<(IV, IV, E)?>>(
        JoinableRegister.instGammaJoinable(oe),
        JoinableRegister.instTotalOrderMin(oe).min,
      ),
    );
    return GammaJoinable(
      apply: (s, a) => JoinableGraph(base.apply(s.data, a)),
      id: base.id,
      comp: base.comp,
      le: (s, t) => base.le(s.data, t.data),
      join: (s, t) => JoinableGraph(base.join(s.data, t.data)),
      gammaJoin: (s, a) => JoinableGraph(base.gammaJoin(s.data, a)),
    );
  }

  Map<IV, JoinableRegister<V?>> get _vertices => data.$1;
  Map<IE, JoinableRegister<(IV, IV, E)?>> get _edges => data.$2;

  /// Get vertex value.
  V? vertex(IV index) => _vertices[index]?.value;

  /// Get edge value.
  (IV, IV, E)? edge(IE index) {
    final e = _edges[index];
    if (e != null) {
      final value = e.value;
      if (value != null) {
        final (src, dst, _) = value;
        if (vertex(src) != null && vertex(dst) != null) return value;
      }
    }
    return null;
  }
}
