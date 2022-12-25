import 'package:test/test.dart';
import 'package:qinhuai/reactive/reactive.dart';

void main() async {
  test('Simple', () {
    var updates = 0;

    final active1 = Active(1);
    final reactive2 = Reactive((ref) {
      updates++;
      return active1.get(ref) + 1;
    });
    final reactive3 = Reactive((ref) {
      updates++;
      return reactive2.get(ref) + 1;
    });
    final reactive4 = Reactive((ref) {
      updates++;
      return reactive3.get(ref) + 1;
    });

    assert(reactive4.get(null) == 4);
    print('Total number of updates = $updates');

    active1.set(233);

    assert(reactive4.get(null) == 236);
    print('Total number of updates = $updates');
  });

  test('Multi-change', () {
    var updates = 0;

    final List<Reactive<int>> a = [];
    final List<Reactive<int>> b = [];

    a.add(Reactive((ref) {
      updates++;
      return 0;
    }));
    b.add(Reactive((ref) {
      updates++;
      return 0;
    }));

    for (var i = 1; i < 16; i++) {
      a.add(Reactive((ref) {
        updates++;
        return a[i - 1].get(ref) + b[i - 1].get(ref);
      }));
      b.add(Reactive((ref) {
        updates++;
        return a[i - 1].get(ref) + b[i - 1].get(ref);
      }));
    }

    assert(a.last.get(null) == 0);
    assert(b.last.get(null) == 0);
    print('Total number of updates = $updates');

    a.first.set((ref) {
      updates++;
      return 1;
    });
    b.first.set((ref) {
      updates++;
      return 1;
    });

    assert(a.last.get(null) == 32768);
    assert(b.last.get(null) == 32768);
    print('Total number of updates = $updates');
  });
}
