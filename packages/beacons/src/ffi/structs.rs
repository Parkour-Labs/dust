/// `(high, low)`.
#[derive(Clone, Copy, PartialEq, Eq)]
#[repr(C)]
pub struct CId(pub u64, pub u64);

#[repr(C)]
pub struct CAtom {
  pub src: CId,
  pub label: u64,
  pub value: CArray<u8>,
}

#[derive(Clone, Copy, PartialEq, Eq)]
#[repr(C)]
pub struct CEdge {
  pub src: CId,
  pub label: u64,
  pub dst: CId,
}

/// `(first, second)`.
#[derive(Clone, Copy, PartialEq, Eq)]
#[repr(C)]
pub struct CPair<T, U>(pub T, pub U);

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
  Atom { id: CId, prev: COption<CAtom>, curr: COption<CAtom> },
  Edge { id: CId, prev: COption<CEdge>, curr: COption<CEdge> },
}

impl From<u128> for CId {
  fn from(value: u128) -> Self {
    Self((value >> 64) as u64, value as u64)
  }
}

impl From<CId> for u128 {
  fn from(value: CId) -> Self {
    ((value.0 as u128) << 64) ^ (value.1 as u128)
  }
}

impl From<(u128, u64, Box<[u8]>)> for CAtom {
  fn from(slv: (u128, u64, Box<[u8]>)) -> Self {
    let (src, label, value) = slv;
    Self { src: src.into(), label, value: value.into() }
  }
}

impl From<(u128, u64, u128)> for CEdge {
  fn from(sld: (u128, u64, u128)) -> Self {
    let (src, label, dst) = sld;
    Self { src: src.into(), label, dst: dst.into() }
  }
}

impl<T, U> From<(T, U)> for CPair<T, U> {
  fn from(value: (T, U)) -> Self {
    let (first, second) = value;
    Self(first, second)
  }
}

impl<T> From<Box<[T]>> for CArray<T> {
  fn from(mut value: Box<[T]>) -> Self {
    let len = value.len() as u64;
    let ptr = value.as_mut_ptr();
    std::mem::forget(value);
    Self { len, ptr }
  }
}

impl<T> From<Vec<T>> for CArray<T> {
  fn from(value: Vec<T>) -> Self {
    Self::from(Box::<[T]>::from(value))
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

impl<T> CArray<T> {
  pub unsafe fn as_ref_unchecked(&self) -> &[T] {
    unsafe { std::slice::from_raw_parts(self.ptr, self.len as usize) }
  }

  pub unsafe fn into_boxed_unchecked(self) -> Box<[T]> {
    unsafe { Box::from_raw(std::slice::from_raw_parts_mut(self.ptr, self.len as usize)) }
  }
}
