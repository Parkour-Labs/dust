#![allow(clippy::missing_safety_doc)]

pub mod structs;

/*
use rand::Rng;
use std::ffi::CStr;

use self::structs::{CArray, CAtom, CEdge, CEventData, CId, COption, CPair, CTriple};
use crate::{fnv64_hash, global};

#[no_mangle]
pub unsafe extern "C" fn init(path: *const std::ffi::c_char) {
  global::init(CStr::from_ptr(path).to_str().unwrap());
}
#[no_mangle]
pub unsafe extern "C" fn make_label(name: *const std::ffi::c_char) -> u64 {
  fnv64_hash(CStr::from_ptr(name).to_str().unwrap())
}
#[no_mangle]
pub unsafe extern "C" fn make_id(name: *const std::ffi::c_char) -> CId {
  CId(0, fnv64_hash(CStr::from_ptr(name).to_str().unwrap()))
}
#[no_mangle]
pub unsafe extern "C" fn random_id() -> CId {
  rand::thread_rng().gen::<u128>().into()
}

#[no_mangle]
pub extern "C" fn get_atom(idh: u64, idl: u64) -> COption<CAtom> {
  let id = CId(idh, idl);
  global::access_store_with(|store| store.atom(id.into())).map(Into::into).into()
}
#[no_mangle]
pub extern "C" fn get_atom_label_value_by_src(srch: u64, srcl: u64) -> CArray<CTriple<CId, u64, CArray<u8>>> {
  let src = CId(srch, srcl);
  global::access_store_with(|store| store.atom_label_value_by_src(src.into()))
    .into_iter()
    .map(|(id, (label, value))| CTriple(id.into(), label, value.into()))
    .collect::<Box<[_]>>()
    .into()
}
#[no_mangle]
pub extern "C" fn get_atom_value_by_src_label(srch: u64, srcl: u64, label: u64) -> CArray<CPair<CId, CArray<u8>>> {
  let src = CId(srch, srcl);
  global::access_store_with(|store| store.atom_value_by_src_label(src.into(), label))
    .into_iter()
    .map(|(id, value)| CPair(id.into(), value.into()))
    .collect::<Box<[_]>>()
    .into()
}
#[no_mangle]
pub extern "C" fn get_atom_src_value_by_label(label: u64) -> CArray<CTriple<CId, CId, CArray<u8>>> {
  global::access_store_with(|store| store.atom_src_value_by_label(label))
    .into_iter()
    .map(|(id, (src, value))| CTriple(id.into(), src.into(), value.into()))
    .collect::<Box<[_]>>()
    .into()
}
#[no_mangle]
pub unsafe extern "C" fn get_atom_src_by_label_value(label: u64, len: u64, ptr: *mut u8) -> CArray<CPair<CId, CId>> {
  let value = CArray { len, ptr };
  global::access_store_with(|store| store.atom_src_by_label_value(label, value.as_ref_unchecked()))
    .into_iter()
    .map(|(id, src)| CPair(id.into(), src.into()))
    .collect::<Box<[_]>>()
    .into()
}
#[no_mangle]
pub extern "C" fn get_edge(idh: u64, idl: u64) -> COption<CEdge> {
  let id = CId(idh, idl);
  global::access_store_with(|store| store.edge(id.into())).map(Into::into).into()
}
#[no_mangle]
pub extern "C" fn get_edge_label_dst_by_src(srch: u64, srcl: u64) -> CArray<CTriple<CId, u64, CId>> {
  let src = CId(srch, srcl);
  global::access_store_with(|store| store.edge_label_dst_by_src(src.into()))
    .into_iter()
    .map(|(id, (label, dst))| CTriple(id.into(), label, dst.into()))
    .collect::<Box<[_]>>()
    .into()
}
#[no_mangle]
pub extern "C" fn get_edge_dst_by_src_label(srch: u64, srcl: u64, label: u64) -> CArray<CPair<CId, CId>> {
  let src = CId(srch, srcl);
  global::access_store_with(|store| store.edge_dst_by_src_label(src.into(), label))
    .into_iter()
    .map(|(id, dst)| CPair(id.into(), dst.into()))
    .collect::<Box<[_]>>()
    .into()
}
#[no_mangle]
pub extern "C" fn get_edge_src_label_by_dst(dsth: u64, dstl: u64) -> CArray<CTriple<CId, CId, u64>> {
  let dst = CId(dsth, dstl);
  global::access_store_with(|store| store.edge_src_label_by_dst(dst.into()))
    .into_iter()
    .map(|(id, (src, label))| CTriple(id.into(), src.into(), label))
    .collect::<Box<[_]>>()
    .into()
}
#[no_mangle]
pub extern "C" fn get_edge_src_by_dst_label(dsth: u64, dstl: u64, label: u64) -> CArray<CPair<CId, CId>> {
  let dst = CId(dsth, dstl);
  global::access_store_with(|store| store.edge_src_by_dst_label(dst.into(), label))
    .into_iter()
    .map(|(id, src)| CPair(id.into(), src.into()))
    .collect::<Box<[_]>>()
    .into()
}

#[no_mangle]
pub extern "C" fn set_atom_none(idh: u64, idl: u64) {
  let id = CId(idh, idl);
  global::access_store_with(|store| store.set_atom(id.into(), None));
}
#[no_mangle]
pub unsafe extern "C" fn set_atom_some(idh: u64, idl: u64, srch: u64, srcl: u64, label: u64, len: u64, ptr: *mut u8) {
  let id = CId(idh, idl);
  let src = CId(srch, srcl);
  let value = CArray { len, ptr };
  global::access_store_with(|store| store.set_atom_ref(id.into(), Some((src.into(), label, value.as_ref_unchecked()))));
}
#[no_mangle]
pub extern "C" fn set_edge_none(idh: u64, idl: u64) {
  let id = CId(idh, idl);
  global::access_store_with(|store| store.set_edge(id.into(), None));
}
#[no_mangle]
pub extern "C" fn set_edge_some(idh: u64, idl: u64, srch: u64, srcl: u64, label: u64, dsth: u64, dstl: u64) {
  let id = CId(idh, idl);
  let src = CId(srch, srcl);
  let dst = CId(dsth, dstl);
  global::access_store_with(|store| store.set_edge(id.into(), Some((src.into(), label, dst.into()))));
}

#[no_mangle]
pub extern "C" fn sync_version() -> CArray<u8> {
  global::access_store_with(|store| store.sync_version()).into()
}
#[no_mangle]
pub unsafe extern "C" fn sync_actions(len: u64, ptr: *mut u8) -> CArray<u8> {
  let version = CArray { len, ptr };
  global::access_store_with(|store| store.sync_actions(version.as_ref_unchecked())).into()
}
#[no_mangle]
pub unsafe extern "C" fn sync_join(len: u64, ptr: *mut u8) -> COption<CArray<u8>> {
  let actions = CArray { len, ptr };
  global::access_store_with(|store| store.sync_join(actions.as_ref_unchecked())).map(Into::into).into()
}
#[no_mangle]
pub extern "C" fn poll_events() -> CArray<CEventData> {
  global::access_store_with(|store| store.barrier()).into()
}

/// Drops the return value of [`get_atom`].
#[no_mangle]
pub unsafe extern "C" fn drop_option_atom(value: COption<CAtom>) {
  if let COption::Some(inner) = value {
    inner.value.as_ref_unchecked();
  }
}
/// Drops the return value of [`get_atom_label_value_by_src`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_u64_array_u8(value: CArray<CTriple<CId, u64, CArray<u8>>>) {
  for elem in value.into_boxed_unchecked().into_vec().into_iter() {
    elem.2.into_boxed_unchecked();
  }
}
/// Drops the return value of [`get_atom_value_by_src_label`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_array_u8(value: CArray<CPair<CId, CArray<u8>>>) {
  for elem in value.into_boxed_unchecked().into_vec().into_iter() {
    elem.1.into_boxed_unchecked();
  }
}
/// Drops the return value of [`get_atom_src_value_by_label`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_id_array_u8(value: CArray<CTriple<CId, CId, CArray<u8>>>) {
  for elem in value.into_boxed_unchecked().into_vec().into_iter() {
    elem.2.into_boxed_unchecked();
  }
}
/// Drops the return value of [`get_atom_src_by_label_value`], [`get_edge_dst_by_src_label`] and [`get_edge_src_by_dst_label`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_id(value: CArray<CPair<CId, CId>>) {
  value.into_boxed_unchecked();
}
/// Drops the return value of [`get_edge_label_dst_by_src`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_u64_id(value: CArray<CTriple<CId, u64, CId>>) {
  value.into_boxed_unchecked();
}
/// Drops the return value of [`get_edge_src_label_by_dst`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_id_u64(value: CArray<CTriple<CId, CId, u64>>) {
  value.into_boxed_unchecked();
}
/// Drops the return value of [`sync_version`] and [`sync_actions`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_u8(value: CArray<u8>) {
  value.into_boxed_unchecked();
}
/// Drops the return value of [`sync_join`].
#[no_mangle]
pub unsafe extern "C" fn drop_option_array_u8(value: COption<CArray<u8>>) {
  if let COption::Some(inner) = value {
    inner.into_boxed_unchecked();
  }
}
/// Drops the return value of [`poll_events`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_event_data(value: CArray<CEventData>) {
  for elem in value.into_boxed_unchecked().into_vec().into_iter() {
    if let CEventData::Atom { id: _, prev, curr } = elem {
      if let COption::Some(inner) = prev {
        inner.value.into_boxed_unchecked();
      }
      if let COption::Some(inner) = curr {
        inner.value.into_boxed_unchecked();
      }
    }
  }
}

#[no_mangle]
pub extern "C" fn test_id() -> CId {
  CId(233, 666)
}
#[no_mangle]
pub extern "C" fn test_id_unsigned() -> CId {
  CId((1 << 63) + 233, (1 << 63) + 666)
}
#[no_mangle]
pub extern "C" fn test_array_u8() -> CArray<u8> {
  CArray::from(Box::from(vec![1, 2, 3, 233, 234]))
}
#[no_mangle]
pub extern "C" fn test_array_id_id() -> CArray<CPair<CId, CId>> {
  let first = CPair(test_id(), test_id_unsigned());
  let second = CPair(CId(0, 1), CId(1, 0));
  CArray::from(Box::from(vec![first, second]))
}
#[no_mangle]
pub extern "C" fn test_array_id_u64_id() -> CArray<CTriple<CId, u64, CId>> {
  let first = CTriple(test_id(), 233, CId(0, 1));
  let second = CTriple(CId(1, 1), 234, CId(1, 0));
  CArray::from(Box::from(vec![first, second]))
}
#[no_mangle]
pub extern "C" fn test_option_atom_some() -> COption<CAtom> {
  COption::Some(CAtom { src: test_id(), label: (1 << 63) + 1, value: test_array_u8() })
}
#[no_mangle]
pub extern "C" fn test_option_atom_none() -> COption<CAtom> {
  COption::None
}
#[no_mangle]
pub extern "C" fn test_option_edge_some() -> COption<CEdge> {
  COption::Some(CEdge { src: test_id(), label: (1 << 63) + 2, dst: test_id_unsigned() })
}
#[no_mangle]
pub extern "C" fn test_option_edge_none() -> COption<CEdge> {
  COption::None
}
#[no_mangle]
pub extern "C" fn test_array_event_data() -> CArray<CEventData> {
  let atom_prev = CAtom { src: test_id(), label: 5, value: CArray::from(Box::from(vec![1, 13])) };
  let atom_curr = CAtom { src: test_id_unsigned(), label: 6, value: CArray::from(Box::from(vec![4, 34])) };
  let edge_prev = CEdge { src: test_id(), label: 7, dst: test_id_unsigned() };
  let edge_curr = CEdge { src: test_id_unsigned(), label: 8, dst: test_id() };
  CArray::from(Box::from(vec![
    CEventData::Atom { id: CId(0, 1), prev: COption::Some(atom_prev), curr: COption::Some(atom_curr) },
    CEventData::Edge { id: CId(1, 0), prev: COption::Some(edge_prev), curr: COption::Some(edge_curr) },
  ]))
}
#[no_mangle]
pub extern "C" fn test_array_u8_big(size: u64) -> CArray<u8> {
  let mut vec = Vec::new();
  vec.resize(size as usize, 233);
  CArray::from(vec)
}
#[no_mangle]
pub extern "C" fn test_array_event_data_big(entries: u64, size: u64) -> CArray<CEventData> {
  let mut vec = Vec::new();
  for _ in 0..entries {
    let atom_prev = CAtom { src: CId(0, 0), label: 0, value: test_array_u8_big(size) };
    let atom_curr = CAtom { src: CId(0, 0), label: 0, value: test_array_u8_big(size) };
    vec.push(CEventData::Atom { id: CId(0, 0), prev: COption::Some(atom_prev), curr: COption::Some(atom_curr) });
  }
  CArray::from(vec)
}
*/