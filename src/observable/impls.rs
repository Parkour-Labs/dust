use super::*;

impl Node {
  /// Creates a pure observer node. Since nodes are almost always wrapped
  /// inside an [`Rc`], it makes most sense to require the given closure to
  /// have static lifetime.
  pub fn new(notify: impl FnMut() + 'static) -> Self {
    Self { out: Default::default(), dirty: Default::default(), notify: Cell::new(Some(Box::new(notify))) }
  }
}

/// Marks all upstream nodes as `dirty`, triggers upstream `notify` functions
/// and clears all out-edges.
pub fn dfs(u: &Node) {
  if let false = u.dirty.replace(true) {
    // Pending nightly feature: https://github.com/rust-lang/rust/issues/50186
    let mut option = u.notify.take();
    if let Some(notify) = option.as_mut() {
      notify();
    }
    u.notify.set(option);
  }
  for weak in u.out.take() {
    if let Some(v) = weak.upgrade() {
      dfs(&v);
    }
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
  /// Marks all upstream nodes as `dirty`, triggers upstream `notify` functions
  /// and clears all out-edges.
  fn notify(&self) {
    for weak in self.out.take() {
      if let Some(v) = weak.upgrade() {
        dfs(&v);
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
  /// Registers an observer (direct upstream node).
  fn register(&self, observer: &Weak<Node>) {
    push(&self.out, observer.clone());
  }
  /// Marks all upstream nodes as `dirty`, triggers upstream `notify` functions
  /// and clears all out-edges.
  fn notify(&self) {
    for weak in self.out.take() {
      if let Some(v) = weak.upgrade() {
        dfs(&v);
      }
    }
  }
  /// Obtains the current value without registering any observer.
  fn peek(&self) -> Ref<'_, T> {
    self.value.borrow()
  }
  /// Obtains the current value and calls `self.register(observer)`.
  fn get(&self, observer: &Weak<Node>) -> Ref<'_, T> {
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
  pub fn peek_mut(&self) -> NotifiedRefMut<'_, T> {
    NotifiedRefMut { inner: Some(self.value.borrow_mut()), origin: self }
  }
  /// Obtains and *locks* the current value by mutable reference, calling
  /// `self.register(observer)` and `self.notify()` when the lock is released.
  pub fn get_mut(&self, observer: &Weak<Node>) -> NotifiedRefMut<'_, T> {
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
  /// Marks all upstream nodes (including `self`) as `dirty`, triggers upstream
  /// `notify` functions and clears all out-edges.
  fn notify(&self) {
    dfs(&self.node);
  }
  /// Obtains the current value without registering any observer.
  fn peek(&self) -> T {
    // If marked `dirty`, recompute and clear the `dirty` flag.
    if let true = self.node.dirty.replace(false) {
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
  /// Registers an observer (direct upstream node).
  fn register(&self, observer: &Weak<Node>) {
    push(&self.node.out, observer.clone());
  }
  /// Marks all upstream nodes (including `self`) as `dirty`, triggers upstream
  /// `notify` functions and clears all out-edges.
  fn notify(&self) {
    dfs(&self.node);
  }
  /// Obtains the current value without registering any observer.
  fn peek(&self) -> Ref<'_, T> {
    // If marked `dirty`, recompute and clear the `dirty` flag.
    if let true = self.node.dirty.replace(false) {
      let mut option = self.recompute.take();
      if let Some(recompute) = option.as_mut() {
        self.value.replace(recompute(&Rc::downgrade(&self.node)));
      }
      self.recompute.set(option);
    }
    self.value.borrow()
  }
  /// Obtains the current value and calls `self.register(observer)`.
  fn get(&self, observer: &Weak<Node>) -> Ref<'_, T> {
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
