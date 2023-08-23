import 'package:test/test.dart';
import 'package:flutter_beacons/reactive.dart';

void main() {
  test('active_reactive_simple', () {
    final a = [Active(1), Active(2), Active(3), Active(4)];
    final b = [
      Reactive((r) => a[0].get(r) + a[1].get(r)),
      Reactive((r) => a[1].get(r) + a[2].get(r)),
      Reactive((r) => a[2].get(r) + a[3].get(r)),
      Reactive((r) => a[3].get(r) + a[0].get(r)),
    ];
    final c = [
      Reactive((r) => a[0].get(r) + a[1].get(r)),
      Reactive((r) => a[1].get(r) + a[2].get(r)),
      Reactive((r) => a[2].get(r) + a[3].get(r)),
      Reactive((r) => a[3].get(r) + a[0].get(r)),
    ];
    final d = [
      Reactive((r) => c[0].get(r) + c[1].get(r)),
      Reactive((r) => c[1].get(r) + c[2].get(r)),
      Reactive((r) => c[2].get(r) + c[3].get(r)),
      Reactive((r) => c[3].get(r) + c[0].get(r)),
    ];
    final sum = Reactive((r) => d[0].get(r) + d[1].get(r) + d[2].get(r) + d[3].get(r));
    assert(sum.peek() == 40);

    c[0].set((r) => b[0].get(r) + b[1].get(r));
    c[1].set((r) => b[1].get(r) + b[2].get(r));
    c[2].set((r) => b[2].get(r) + b[3].get(r));
    c[3].set((r) => b[3].get(r) + b[0].get(r));
    assert(sum.peek() == 80);

    a[0].set(233);
    assert(sum.peek() == 80 + 8 * 232);
    assert(c[3].peek() == 8 + 2 * 232);
  });

  test('dynamic_dependencies_simple', () {
    var updates = 0;

    final a = [
      Reactive((_) {
        updates++;
        return 0;
      })
    ];
    final b = [
      Reactive((_) {
        updates++;
        return 0;
      })
    ];

    for (var i = 1; i < 16; i++) {
      a.add(Reactive((r) {
        updates++;
        return a[i - 1].get(r) + b[i - 1].get(r);
      }));
      b.add(Reactive((r) {
        updates++;
        return a[i - 1].get(r) + b[i - 1].get(r);
      }));
    }

    assert(a.last.peek() == 0);
    assert(b.last.peek() == 0);
    assert(updates == 32);

    a[0].set((_) {
      updates++;
      return 1;
    });
    b[0].set((_) {
      updates++;
      return 1;
    });

    assert(a.last.peek() == 32768);
    assert(b.last.peek() == 32768);
    assert(updates == 64);
  });
}
