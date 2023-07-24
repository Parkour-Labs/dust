use super::*;

impl Node {
  /// Creates a pure observer node.
  pub fn new() -> Self {
    Self { out: Default::default(), notified: Default::default() }
  }
  /// Marks all upstream nodes as `notified` and clears all out-edges.
  pub fn notify(&self) {
    for weak in self.out.take() {
      if let Some(v) = weak.upgrade() {
        v.notify();
      }
    }
    self.notified.set(true);
  }
}

/// Pushes an element to a [`Cell<Vec<T>>`].
fn push<T>(cell: &Cell<Vec<T>>, elem: T) {
  let mut vec = cell.take();
  vec.push(elem);
  cell.set(vec);
}

impl<T: Copy> Observable<T> for Active<T> {
  /// Registers an observer (direct upstream node).
  fn register(&self, observer: &Weak<Node>) {
    push(&self.out, observer.clone());
  }
  /// Marks all upstream nodes as `notified` and clears all out-edges.
  fn notify(&self) {
    for weak in self.out.take() {
      if let Some(v) = weak.upgrade() {
        v.notify();
      }
    }
  }
  /// Obtains the current value without registering any observer.
  fn peek(&self) -> T {
    self.value.get()
  }
  /// Obtains the current value and calls `self.register(observer)`.
  fn get(&self, observer: &Weak<Node>) -> T {
    self.register(observer);
    self.peek()
  }
}

impl<T: Copy> Active<T> {
  /// Creates a new [`Active`] value.
  pub fn new(value: T) -> Self {
    Self { out: Default::default(), value: Cell::new(value) }
  }
  /// Updates the current value and calls `self.notify()`.
  pub fn set(&self, value: T) {
    self.value.set(value);
    self.notify();
  }
}

impl<T> ObservableRef<T> for ActiveRef<T> {
  type Ref<'a> = std::cell::Ref<'a, T> where T: 'a, Self: 'a;

  /// Registers an observer (direct upstream node).
  fn register(&self, observer: &Weak<Node>) {
    push(&self.out, observer.clone());
  }
  /// Marks all upstream nodes as `notified` and clears all out-edges.
  fn notify(&self) {
    for weak in self.out.take() {
      if let Some(v) = weak.upgrade() {
        v.notify();
      }
    }
  }
  /// Obtains the current value without registering any observer.
  fn peek(&self) -> Self::Ref<'_> {
    self.value.borrow()
  }
  /// Obtains the current value and calls `self.register(observer)`.
  fn get(&self, observer: &Weak<Node>) -> Self::Ref<'_> {
    self.register(observer);
    self.peek()
  }
}

impl<T> ActiveRef<T> {
  /// Creates a new [`ActiveRef`] reference.
  pub fn new(value: T) -> Self {
    Self { out: Default::default(), value: RefCell::new(value) }
  }
  /// Obtains and *locks* the current value by mutable reference, calling
  /// `self.notify()` when the lock is released, without registering any
  /// observer.
  pub fn peek_mut(&self) -> NotifiedRefMut<'_, T, Self> {
    NotifiedRefMut { inner: Some(self.value.borrow_mut()), origin: self }
  }
  /// Obtains and *locks* the current value by mutable reference, calling
  /// `self.register(observer)` and `self.notify()` when the lock is released.
  pub fn get_mut(&self, observer: &Weak<Node>) -> NotifiedRefMut<'_, T, Self> {
    self.register(observer);
    self.peek_mut()
  }
  /// Updates the current value and calls `self.notify()`.
  pub fn set(&self, value: T) {
    self.value.replace(value);
    self.notify();
  }
}

impl<'a, T: Copy> Observable<T> for Reactive<'a, T> {
  /// Registers an observer (direct upstream node).
  fn register(&self, observer: &Weak<Node>) {
    push(&self.node.out, observer.clone());
  }
  /// Marks all upstream nodes as `notified` and clears all out-edges.
  fn notify(&self) {
    self.node.notify();
  }
  /// Obtains the current value without registering any observer.
  fn peek(&self) -> T {
    // If marked `notified`, recompute and clear the `notified` flag.
    if let true = self.node.notified.replace(false) {
      let mut option = self.recompute.take();
      if let Some(recompute) = option.as_mut() {
        self.value.set(recompute(&Rc::downgrade(&self.node)));
      }
      self.recompute.set(option);
    }
    self.value.get()
  }
  /// Obtains the current value and calls `self.register(observer)`.
  fn get(&self, observer: &Weak<Node>) -> T {
    self.register(observer);
    self.peek()
  }
}

impl<'a, T: Copy> Reactive<'a, T> {
  /// Creates a new [`Reactive`] value.
  /// This will invoke `recompute` *immediately*.
  pub fn new(mut recompute: impl FnMut(&Weak<Node>) -> T + 'a) -> Self {
    let node = Default::default();
    let value = Cell::new(recompute(&Rc::downgrade(&node)));
    Self { node, value, recompute: Cell::new(Some(Box::new(recompute))) }
  }
  /// Updates the recomputation function and calls `self.notify()`.
  /// Note that currently it does *not* clear in-edges that might present.
  #[allow(unused_must_use)]
  pub fn set(&self, recompute: impl FnMut(&Weak<Node>) -> T + 'a) {
    self.recompute.set(Some(Box::new(recompute)));
    self.notify();
  }
}

impl<'a, T> ObservableRef<T> for ReactiveRef<'a, T> {
  type Ref<'b> = std::cell::Ref<'b, T> where T: 'b, Self: 'b;

  /// Registers an observer (direct upstream node).
  fn register(&self, observer: &Weak<Node>) {
    push(&self.node.out, observer.clone());
  }
  /// Marks all upstream nodes as `notified` and clears all out-edges.
  fn notify(&self) {
    self.node.notify();
  }
  /// Obtains the current value without registering any observer.
  fn peek(&self) -> Self::Ref<'_> {
    // If marked `notified`, recompute and clear the `notified` flag.
    if let true = self.node.notified.replace(false) {
      let mut option = self.recompute.take();
      if let Some(recompute) = option.as_mut() {
        self.value.replace(recompute(&Rc::downgrade(&self.node)));
      }
      self.recompute.set(option);
    }
    self.value.borrow()
  }
  /// Obtains the current value and calls `self.register(observer)`.
  fn get(&self, observer: &Weak<Node>) -> Self::Ref<'_> {
    self.register(observer);
    self.peek()
  }
}

impl<'a, T> ReactiveRef<'a, T> {
  /// Creates a new [`ReactiveRef`] reference.
  /// This will invoke `recompute` *immediately*.
  pub fn new(mut recompute: impl FnMut(&Weak<Node>) -> T + 'a) -> Self {
    let node = Default::default();
    let value = RefCell::new(recompute(&Rc::downgrade(&node)));
    Self { node, value, recompute: Cell::new(Some(Box::new(recompute))) }
  }
  /// Updates the recomputation function and calls `self.notify()`.
  /// Note that currently it does *not* clear in-edges that might present.
  #[allow(unused_must_use)]
  pub fn set(&self, recompute: impl FnMut(&Weak<Node>) -> T + 'a) {
    self.recompute.set(Some(Box::new(recompute)));
    self.notify();
  }
}
