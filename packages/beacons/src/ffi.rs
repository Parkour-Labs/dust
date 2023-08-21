#![allow(clippy::missing_safety_doc)]

pub mod structs;

use rand::Rng;
use std::ffi::CStr;

use self::structs::{CArray, CEdge, CEventData, CId, COption, CPair};
use crate::{fnv64_hash, global::*};

pub unsafe fn hash(name: *const std::ffi::c_char) -> u64 {
  fnv64_hash(CStr::from_ptr(name).to_str().unwrap())
}
pub fn get_node(id: CId) -> COption<u64> {
  access_store_with(|store| store.node(id.into())).into()
}
pub fn get_atom(id: CId) -> COption<CArray<u8>> {
  access_store_with(|store| store.atom(id.into()).map(CArray::from_leaked)).into()
}
pub fn get_edge(id: CId) -> COption<CEdge> {
  access_store_with(|store| store.edge(id.into())).map(Into::into).into()
}
pub fn get_edges_by_src(src: CId) -> CArray<CPair<CId, CEdge>> {
  let boxed = access_store_with(|store| store.edges_by_src(src.into()))
    .into_iter()
    .map(|(id, edge)| CPair { first: id.into(), second: edge.into() })
    .collect();
  CArray::from_leaked(boxed)
}
pub fn get_id_dst_by_src_label(src: CId, label: u64) -> CArray<CPair<CId, CId>> {
  let boxed = access_store_with(|store| store.id_dst_by_src_label(src.into(), label))
    .into_iter()
    .map(|(id, dst)| CPair { first: id.into(), second: dst.into() })
    .collect();
  CArray::from_leaked(boxed)
}
pub fn get_id_src_by_dst_label(dst: CId, label: u64) -> CArray<CPair<CId, CId>> {
  let boxed = access_store_with(|store| store.id_src_by_dst_label(dst.into(), label))
    .into_iter()
    .map(|(id, src)| CPair { first: id.into(), second: src.into() })
    .collect();
  CArray::from_leaked(boxed)
}

pub fn set_node(id: CId, some: bool, value: u64) {
  let value = if some { Some(value) } else { None };
  access_store_with(|store| store.set_node(id.into(), value));
}
pub unsafe fn set_atom(id: CId, some: bool, value: CArray<u8>) {
  let value = if some { Some(value.as_ref_unchecked()) } else { None };
  access_store_with(|store| store.set_atom_ref(id.into(), value));
}
pub fn set_edge(id: CId, some: bool, value: CEdge) {
  let value = if some { Some(value.into()) } else { None };
  access_store_with(|store| store.set_edge(id.into(), value));
}
pub fn set_edge_dst(id: CId, some: bool, dst: CId) {
  let dst = if some { Some(dst.into()) } else { None };
  access_store_with(|store| store.set_edge_dst(id.into(), dst.unwrap_or_else(|| rand::thread_rng().gen())));
}

pub fn subscribe_node(id: CId, port: u64) {
  access_store_with(|store| store.subscribe_node(id.into(), port));
}
pub fn unsubscribe_node(id: CId, port: u64) {
  access_store_with(|store| store.unsubscribe_node(id.into(), port));
}
pub fn subscribe_atom(id: CId, port: u64) {
  access_store_with(|store| store.subscribe_atom(id.into(), port));
}
pub fn unsubscribe_atom(id: CId, port: u64) {
  access_store_with(|store| store.unsubscribe_atom(id.into(), port));
}
pub fn subscribe_edge(id: CId, port: u64) {
  access_store_with(|store| store.subscribe_edge(id.into(), port));
}
pub fn unsubscribe_edge(id: CId, port: u64) {
  access_store_with(|store| store.unsubscribe_edge(id.into(), port));
}
pub fn subscribe_multiedge(src: CId, label: u64, port: u64) {
  access_store_with(|store| store.subscribe_multiedge(src.into(), label, port));
}
pub fn unsubscribe_multiedge(src: CId, label: u64, port: u64) {
  access_store_with(|store| store.unsubscribe_multiedge(src.into(), label, port));
}
pub fn subscribe_backedge(dst: CId, label: u64, port: u64) {
  access_store_with(|store| store.subscribe_backedge(dst.into(), label, port));
}
pub fn unsubscribe_backedge(dst: CId, label: u64, port: u64) {
  access_store_with(|store| store.unsubscribe_backedge(dst.into(), label, port));
}

pub fn sync_version() -> CArray<u8> {
  CArray::from_leaked(access_store_with(|store| store.sync_version()))
}
pub unsafe fn sync_actions(version: CArray<u8>) -> CArray<u8> {
  CArray::from_leaked(access_store_with(|store| store.sync_actions(version.as_ref_unchecked())))
}
pub unsafe fn sync_join(actions: CArray<u8>) {
  access_store_with(|store| store.sync_join(actions.as_ref_unchecked()))
}

pub fn poll_events() -> CArray<CPair<u64, CEventData>> {
  let boxed = access_store_with(|store| store.poll_events())
    .into_iter()
    .map(|(port, data)| CPair { first: port, second: data })
    .collect();
  CArray::from_leaked(boxed)
}

/// Drops the return value of [`get_atom`].
pub unsafe fn drop_option_array_u8(value: COption<CArray<u8>>) {
  if let COption::Some(inner) = value {
    inner.into_boxed_unchecked();
  }
}
/// Drops the return value of [`sync_version`] and [`sync_actions`].
pub unsafe fn drop_array_u8(value: CArray<u8>) {
  value.into_boxed_unchecked();
}
/// Drops the return value of [`get_edges_by_src`].
pub unsafe fn drop_array_id_edge(value: CArray<CPair<CId, CEdge>>) {
  value.into_boxed_unchecked();
}
/// Drops the return value of [`get_id_dst_by_src_label`] and [`get_id_src_by_dst_label`].
pub unsafe fn drop_array_id_id(value: CArray<CPair<CId, CId>>) {
  value.into_boxed_unchecked();
}
/// Drops the return value of [`poll_events`].
pub unsafe fn drop_array_u64_event_data(value: CArray<CPair<u64, CEventData>>) {
  let value = value.into_boxed_unchecked();
  // See: https://github.com/rust-lang/rust/issues/59878
  for CPair { first: _, second } in value.into_vec().into_iter() {
    // Atom entries require manual drop of inner array.
    if let CEventData::Atom { value: COption::Some(inner) } = second {
      inner.into_boxed_unchecked();
    }
  }
}

#[doc(hidden)]
#[macro_export]
macro_rules! export_symbol {
  ( fn $name:ident( $($arg:ident: $type:ty),* ) -> $ret:ty ) => {
    #[allow(clippy::missing_safety_doc)]
    #[no_mangle]
    pub unsafe extern "C" fn $name( $($arg: $type),* ) -> $ret {
      $crate::ffi::$name( $($arg),* )
    }
  };
  ( fn $name:ident( $($arg:ident: $type:ty),* ) ) => {
    export_symbol!(fn $name( $($arg: $type),* ) -> ());
  }
}

/// As a workaround for rust-lang/rust#6342, you can use this macro to export
/// all FFI functions in the root crate.
/// See: https://github.com/rust-lang/rfcs/issues/2771
#[macro_export]
macro_rules! export_symbols {
  () => {
    export_symbol!(fn hash(name: *const std::ffi::c_char) -> u64);
    export_symbol!(fn get_node(id: CId) -> COption<u64>);
    export_symbol!(fn get_atom(id: CId) -> COption<CArray<u8>>);
    export_symbol!(fn get_edge(id: CId) -> COption<CEdge>);
    export_symbol!(fn get_edges_by_src(src: CId) -> CArray<CPair<CId, CEdge>>);
    export_symbol!(fn get_id_dst_by_src_label(src: CId, label: u64) -> CArray<CPair<CId, CId>>);
    export_symbol!(fn get_id_src_by_dst_label(dst: CId, label: u64) -> CArray<CPair<CId, CId>>);

    export_symbol!(fn set_node(id: CId, some: bool, value: u64));
    export_symbol!(fn set_atom(id: CId, some: bool, value: CArray<u8>));
    export_symbol!(fn set_edge(id: CId, some: bool, value: CEdge));
    export_symbol!(fn set_edge_dst(id: CId, some: bool, dst: CId));

    export_symbol!(fn subscribe_node(id: CId, port: u64));
    export_symbol!(fn unsubscribe_node(id: CId, port: u64));
    export_symbol!(fn subscribe_atom(id: CId, port: u64));
    export_symbol!(fn unsubscribe_atom(id: CId, port: u64));
    export_symbol!(fn subscribe_edge(id: CId, port: u64));
    export_symbol!(fn unsubscribe_edge(id: CId, port: u64));
    export_symbol!(fn subscribe_multiedge(src: CId, label: u64, port: u64));
    export_symbol!(fn unsubscribe_multiedge(src: CId, label: u64, port: u64));
    export_symbol!(fn subscribe_backedge(dst: CId, label: u64, port: u64));
    export_symbol!(fn unsubscribe_backedge(dst: CId, label: u64, port: u64));

    export_symbol!(fn sync_version() -> CArray<u8>);
    export_symbol!(fn sync_actions(version: CArray<u8>) -> CArray<u8>);
    export_symbol!(fn sync_join(actions: CArray<u8>));
    export_symbol!(fn poll_events() -> CArray<CPair<u64, CEventData>>);

    export_symbol!(fn drop_option_array_u8(value: COption<CArray<u8>>));
    export_symbol!(fn drop_array_u8(value: CArray<u8>));
    export_symbol!(fn drop_array_id_edge(value: CArray<CPair<CId, CEdge>>));
    export_symbol!(fn drop_array_id_id(value: CArray<CPair<CId, CId>>));
    export_symbol!(fn drop_array_u64_event_data(value: CArray<CPair<u64, CEventData>>));
  };
}

pub fn test_id() -> CId {
  CId { high: 233, low: 666 }
}
pub fn test_id_unsigned() -> CId {
  CId { high: (1 << 63) + 233, low: (1 << 63) + 666 }
}
pub fn test_id_input(id: CId) -> bool {
  id == test_id()
}
pub fn test_id_input_unsigned(id: CId) -> bool {
  id == test_id_unsigned()
}
pub fn test_edge() -> CEdge {
  CEdge { src: test_id(), label: (1 << 63) + 1, dst: test_id_unsigned() }
}
pub fn test_edge_input(edge: CEdge) -> bool {
  edge == test_edge()
}

pub fn test_array_u8() -> CArray<u8> {
  CArray::from_leaked(Box::new([1, 2, 3, 233, 234]))
}
pub fn test_array_pair_id_id() -> CArray<CPair<CId, CId>> {
  let first = CPair { first: test_id(), second: test_id_unsigned() };
  let second = CPair { first: CId { high: 0, low: 1 }, second: CId { high: 1, low: 0 } };
  CArray::from_leaked(Box::new([first, second]))
}
pub fn test_array_pair_id_edge() -> CArray<CPair<CId, CEdge>> {
  let first = CPair { first: test_id(), second: test_edge() };
  let second = CPair {
    first: CId { high: 1, low: 1 },
    second: CEdge { src: CId { high: 0, low: 1 }, label: 1, dst: CId { high: 1, low: 0 } },
  };
  CArray::from_leaked(Box::new([first, second]))
}

pub fn test_option_u64_none() -> COption<u64> {
  COption::None
}
pub fn test_option_u64_some() -> COption<u64> {
  COption::Some(233)
}
pub fn test_option_array_u8_some() -> COption<CArray<u8>> {
  COption::Some(test_array_u8())
}
pub fn test_option_edge_some() -> COption<CEdge> {
  COption::Some(test_edge())
}

pub fn test_array_pair_u64_event_data() -> CArray<CPair<u64, CEventData>> {
  let node = CEventData::Node { value: test_option_u64_some() };
  let atom = CEventData::Atom { value: test_option_array_u8_some() };
  let edge = CEventData::Edge { value: test_option_edge_some() };
  let multiedge_insert = CEventData::MultiedgeInsert { id: test_id(), dst: test_id_unsigned() };
  let multiedge_remove = CEventData::MultiedgeRemove { id: test_id_unsigned(), dst: test_id() };
  let backedge_insert = CEventData::BackedgeInsert { id: test_id(), src: test_id_unsigned() };
  let backedge_remove = CEventData::BackedgeRemove { id: test_id_unsigned(), src: test_id() };
  CArray::from_leaked(Box::from([
    CPair { first: 1, second: node },
    CPair { first: 2, second: atom },
    CPair { first: 3, second: edge },
    CPair { first: 4, second: multiedge_insert },
    CPair { first: 5, second: multiedge_remove },
    CPair { first: 6, second: backedge_insert },
    CPair { first: 7, second: backedge_remove },
  ]))
}

pub fn test_array_u8_big(size: u64) -> CArray<u8> {
  let mut vec = Vec::new();
  vec.resize(size as usize, 233);
  CArray::from_leaked(vec.into())
}

pub fn test_array_pair_u64_event_data_big(entries: u64, size: u64) -> CArray<CPair<u64, CEventData>> {
  let mut vec = Vec::new();
  for _ in 0..entries {
    vec.push(CPair { first: 1, second: CEventData::Atom { value: COption::Some(test_array_u8_big(size)) } });
  }
  CArray::from_leaked(vec.into())
}

/// As a workaround for rust-lang/rust#6342, you can use this macro to export
/// all FFI functions in the root crate.
/// See: https://github.com/rust-lang/rfcs/issues/2771
#[macro_export]
macro_rules! export_test_symbols {
  () => {
    export_symbol!(fn test_id() -> CId);
    export_symbol!(fn test_id_unsigned() -> CId);
    export_symbol!(fn test_id_input(id: CId) -> bool);
    export_symbol!(fn test_id_input_unsigned(id: CId) -> bool);
    export_symbol!(fn test_edge() -> CEdge);
    export_symbol!(fn test_edge_input(edge: CEdge) -> bool);
    export_symbol!(fn test_array_u8() -> CArray<u8>);
    export_symbol!(fn test_array_pair_id_id() -> CArray<CPair<CId, CId>>);
    export_symbol!(fn test_array_pair_id_edge() -> CArray<CPair<CId, CEdge>>);
    export_symbol!(fn test_option_u64_none() -> COption<u64>);
    export_symbol!(fn test_option_u64_some() -> COption<u64>);
    export_symbol!(fn test_option_array_u8_some() -> COption<CArray<u8>>);
    export_symbol!(fn test_option_edge_some() -> COption<CEdge>);
    export_symbol!(fn test_array_pair_u64_event_data() -> CArray<CPair<u64, CEventData>>);
    export_symbol!(fn test_array_u8_big(size: u64) -> CArray<u8>);
    export_symbol!(fn test_array_pair_u64_event_data_big(entries: u64, size: u64) -> CArray<CPair<u64, CEventData>>);
  };
}
