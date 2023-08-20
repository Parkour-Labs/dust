#[derive(Clone, Copy, PartialEq, Eq)]
#[repr(C)]
pub struct CId {
  pub high: u64,
  pub low: u64,
}

#[derive(Clone, Copy, PartialEq, Eq)]
#[repr(C)]
pub struct CEdge {
  pub src: CId,
  pub label: u64,
  pub dst: CId,
}

#[derive(Clone, Copy, PartialEq, Eq)]
#[repr(C)]
pub struct CPair<T, U> {
  pub first: T,
  pub second: U,
}

#[repr(C)]
pub struct CArray<T> {
  pub len: u64,
  pub ptr: *mut T,
}

/// See: https://github.com/rust-lang/rfcs/blob/master/text/2195-really-tagged-unions.md
#[derive(Clone, Copy, PartialEq, Eq)]
#[repr(C, u8)]
pub enum COption<T> {
  None,
  Some(T),
}

#[repr(C, u8)]
pub enum CEventData {
  Node { value: COption<u64> },
  Atom { value: COption<CArray<u8>> },
  Edge { value: COption<CEdge> },
  MultiedgeInsert { id: CId, dst: CId },
  MultiedgeRemove { id: CId, dst: CId },
  BackedgeInsert { id: CId, src: CId },
  BackedgeRemove { id: CId, src: CId },
}

impl From<u128> for CId {
  fn from(value: u128) -> Self {
    Self { high: (value >> 64) as u64, low: value as u64 }
  }
}

impl From<CId> for u128 {
  fn from(value: CId) -> Self {
    ((value.high as u128) << 64) ^ (value.low as u128)
  }
}

impl From<(u128, u64, u128)> for CEdge {
  fn from(value: (u128, u64, u128)) -> Self {
    let (src, label, dst) = value;
    Self { src: src.into(), label, dst: dst.into() }
  }
}

impl From<CEdge> for (u128, u64, u128) {
  fn from(value: CEdge) -> Self {
    (value.src.into(), value.label, value.dst.into())
  }
}

impl<T, U> From<(T, U)> for CPair<T, U> {
  fn from(value: (T, U)) -> Self {
    let (first, second) = value;
    Self { first, second }
  }
}

impl<T, U> From<CPair<T, U>> for (T, U) {
  fn from(value: CPair<T, U>) -> Self {
    (value.first, value.second)
  }
}

impl<T> CArray<T> {
  /// This will **move** the content of the box to the `(length, pointer)` pair.
  pub fn from_leaked(mut value: Box<[T]>) -> Self {
    let len = value.len() as u64;
    let ptr = value.as_mut_ptr();
    std::mem::forget(value);
    Self { len, ptr }
  }

  pub unsafe fn as_ref_unchecked(&self) -> &[T] {
    unsafe { std::slice::from_raw_parts(self.ptr, self.len as usize) }
  }

  pub unsafe fn into_boxed_unchecked(self) -> Box<[T]> {
    unsafe { Box::from_raw(std::slice::from_raw_parts_mut(self.ptr, self.len as usize)) }
  }
}

impl<T> From<Option<T>> for COption<T> {
  fn from(value: Option<T>) -> Self {
    match value {
      None => COption::None,
      Some(inner) => COption::Some(inner),
    }
  }
}

impl<T> From<COption<T>> for Option<T> {
  fn from(value: COption<T>) -> Self {
    match value {
      COption::None => None,
      COption::Some(inner) => Some(inner),
    }
  }
}
