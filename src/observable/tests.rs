use std::cell::RefCell;

use super::*;

#[test]
fn simple() {
  let a = [Active::new(1), Active::new(2), Active::new(3), Active::new(4)];
  let b = [
    Reactive::new(|r| a[0].get(r) + a[1].get(r)),
    Reactive::new(|r| a[1].get(r) + a[2].get(r)),
    Reactive::new(|r| a[2].get(r) + a[3].get(r)),
    Reactive::new(|r| a[3].get(r) + a[0].get(r)),
  ];
  let c = [
    Reactive::new(|r| a[0].get(r) + a[1].get(r)),
    Reactive::new(|r| a[1].get(r) + a[2].get(r)),
    Reactive::new(|r| a[2].get(r) + a[3].get(r)),
    Reactive::new(|r| a[3].get(r) + a[0].get(r)),
  ];
  let d = [
    Reactive::new(|r| c[0].get(r) + c[1].get(r)),
    Reactive::new(|r| c[1].get(r) + c[2].get(r)),
    Reactive::new(|r| c[2].get(r) + c[3].get(r)),
    Reactive::new(|r| c[3].get(r) + c[0].get(r)),
  ];
  let sum = Reactive::new(|r| d[0].get(r) + d[1].get(r) + d[2].get(r) + d[3].get(r));
  assert_eq!(sum.peek(), 40);

  c[0].set(|r| b[0].get(r) + b[1].get(r));
  c[1].set(|r| b[1].get(r) + b[2].get(r));
  c[2].set(|r| b[2].get(r) + b[3].get(r));
  c[3].set(|r| b[3].get(r) + b[0].get(r));
  assert_eq!(sum.peek(), 80);

  a[0].set(233);
  assert_eq!(sum.peek(), 80 + 8 * 232);
  assert_eq!(c[3].peek(), 8 + 2 * 232);
}

#[test]
fn simple_ref() {
  let a = [ActiveRef::new(1), ActiveRef::new(2), ActiveRef::new(3), ActiveRef::new(4)];
  let b = [
    ReactiveRef::new(|r| *a[0].get(r) + *a[1].get(r)),
    ReactiveRef::new(|r| *a[1].get(r) + *a[2].get(r)),
    ReactiveRef::new(|r| *a[2].get(r) + *a[3].get(r)),
    ReactiveRef::new(|r| *a[3].get(r) + *a[0].get(r)),
  ];
  let c = [
    ReactiveRef::new(|r| *a[0].get(r) + *a[1].get(r)),
    ReactiveRef::new(|r| *a[1].get(r) + *a[2].get(r)),
    ReactiveRef::new(|r| *a[2].get(r) + *a[3].get(r)),
    ReactiveRef::new(|r| *a[3].get(r) + *a[0].get(r)),
  ];
  let d = [
    ReactiveRef::new(|r| (*c[0].get(r) + *c[1].get(r)).to_string()),
    ReactiveRef::new(|r| (*c[1].get(r) + *c[2].get(r)).to_string()),
    ReactiveRef::new(|r| (*c[2].get(r) + *c[3].get(r)).to_string()),
    ReactiveRef::new(|r| (*c[3].get(r) + *c[0].get(r)).to_string()),
  ];
  let sum = ReactiveRef::new(|r| {
    (d[0].get(r).parse::<i32>().unwrap()
      + d[1].get(r).parse::<i32>().unwrap()
      + d[2].get(r).parse::<i32>().unwrap()
      + d[3].get(r).parse::<i32>().unwrap())
    .to_string()
  });
  assert_eq!(*sum.peek(), 40.to_string());

  c[0].set(|r| *b[0].get(r) + *b[1].get(r));
  c[1].set(|r| *b[1].get(r) + *b[2].get(r));
  c[2].set(|r| *b[2].get(r) + *b[3].get(r));
  c[3].set(|r| *b[3].get(r) + *b[0].get(r));
  assert_eq!(*sum.peek(), 80.to_string());

  *a[0].peek_mut() = 233;
  assert_eq!(*sum.peek(), (80 + 8 * 232).to_string());
  assert_eq!(*c[3].peek(), 8 + 2 * 232);
}

#[test]
fn dynamic_dependencies() {
  let updates = RefCell::new(0);

  // Rust does not drop the elements of a `Vec` before the `Vec` itself is
  // dropped, so closure dependencies must outlive the `Vec`.
  let wa;
  let wb;

  let a = Rc::new(RefCell::new(vec![Reactive::new(|_| {
    *updates.borrow_mut() += 1;
    0
  })]));
  let b = Rc::new(RefCell::new(vec![Reactive::new(|_| {
    *updates.borrow_mut() += 1;
    0
  })]));

  wa = Rc::downgrade(&a);
  wb = Rc::downgrade(&b);

  for i in 1..16 {
    // See: https://stackoverflow.com/questions/67230394/can-i-capture-some-things-by-reference-and-others-by-value-in-a-closure
    let ra = Reactive::new({
      let wa = &wa;
      let wb = &wb;
      let updates = &updates;
      move |r| {
        *updates.borrow_mut() += 1;
        if let (Some(a), Some(b)) = (wa.upgrade(), wb.upgrade()) {
          return a.borrow()[i - 1].get(r) + b.borrow()[i - 1].get(r);
        }
        0
      }
    });
    let rb = Reactive::new({
      let wa = &wa;
      let wb = &wb;
      let updates = &updates;
      move |r| {
        *updates.borrow_mut() += 1;
        if let (Some(a), Some(b)) = (wa.upgrade(), wb.upgrade()) {
          return a.borrow()[i - 1].get(r) + b.borrow()[i - 1].get(r);
        }
        0
      }
    });
    a.borrow_mut().push(ra);
    b.borrow_mut().push(rb);
  }

  assert_eq!(a.borrow()[a.borrow().len() - 1].peek(), 0);
  assert_eq!(b.borrow()[b.borrow().len() - 1].peek(), 0);
  assert_eq!(*updates.borrow(), 32);

  a.borrow()[0].set(|_| {
    *updates.borrow_mut() += 1;
    1
  });
  b.borrow()[0].set(|_| {
    *updates.borrow_mut() += 1;
    1
  });

  assert_eq!(a.borrow()[a.borrow().len() - 1].peek(), 32768);
  assert_eq!(b.borrow()[b.borrow().len() - 1].peek(), 32768);
  assert_eq!(*updates.borrow(), 64);
}
