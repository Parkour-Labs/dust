#![allow(clippy::missing_safety_doc)]

pub mod structs;

use rand::Rng;
use std::ffi::CStr;

use self::structs::{CArray, CEdge, CEventData, CId, COption, CPair};
use crate::{fnv64_hash, global::*};

#[no_mangle]
pub unsafe extern "C" fn hash(name: *const i8) -> u64 {
  fnv64_hash(CStr::from_ptr(name).to_str().unwrap())
}
#[no_mangle]
pub extern "C" fn get_node(id: CId) -> COption<u64> {
  access_store_with(|store| store.node(id.into())).into()
}
#[no_mangle]
pub extern "C" fn get_atom(id: CId) -> COption<CArray<u8>> {
  access_store_with(|store| store.atom(id.into()).map(CArray::from_copy_leaked)).into()
}
#[no_mangle]
pub extern "C" fn get_edge(id: CId) -> COption<CEdge> {
  access_store_with(|store| store.edge(id.into())).map(Into::into).into()
}
#[no_mangle]
pub extern "C" fn get_edges_by_src(src: CId) -> CArray<CPair<CId, CEdge>> {
  let boxed = access_store_with(|store| store.edges_by_src(src.into()))
    .into_iter()
    .map(|(id, edge)| CPair { first: id.into(), second: edge.into() })
    .collect();
  CArray::from_leaked(boxed)
}
#[no_mangle]
pub extern "C" fn get_id_dst_by_src_label(src: CId, label: u64) -> CArray<CPair<CId, CId>> {
  let boxed = access_store_with(|store| store.id_dst_by_src_label(src.into(), label))
    .into_iter()
    .map(|(id, dst)| CPair { first: id.into(), second: dst.into() })
    .collect();
  CArray::from_leaked(boxed)
}
#[no_mangle]
pub extern "C" fn get_id_src_by_dst_label(dst: CId, label: u64) -> CArray<CPair<CId, CId>> {
  let boxed = access_store_with(|store| store.id_src_by_dst_label(dst.into(), label))
    .into_iter()
    .map(|(id, src)| CPair { first: id.into(), second: src.into() })
    .collect();
  CArray::from_leaked(boxed)
}

#[no_mangle]
pub extern "C" fn set_node(id: CId, some: bool, value: u64) {
  let value = if some { Some(value) } else { None };
  access_store_with(|store| store.set_node(id.into(), value));
}
#[no_mangle]
pub extern "C" fn set_atom(id: CId, some: bool, value: CArray<u8>) {
  let value = if some { Some(value.copy_unchecked()) } else { None };
  access_store_with(|store| store.set_atom(id.into(), value));
}
#[no_mangle]
pub extern "C" fn set_edge(id: CId, some: bool, value: CEdge) {
  let value = if some { Some(value.into()) } else { None };
  access_store_with(|store| store.set_edge(id.into(), value));
}
#[no_mangle]
pub extern "C" fn set_edge_dst(id: CId, some: bool, dst: CId) {
  let dst = if some { Some(dst.into()) } else { None };
  access_store_with(|store| store.set_edge_dst(id.into(), dst.unwrap_or_else(|| rand::thread_rng().gen())));
}

#[no_mangle]
pub extern "C" fn subscribe_node(id: CId, port: u64) {
  access_store_with(|store| store.subscribe_node(id.into(), port));
}
#[no_mangle]
pub extern "C" fn unsubscribe_node(id: CId, port: u64) {
  access_store_with(|store| store.unsubscribe_node(id.into(), port));
}
#[no_mangle]
pub extern "C" fn subscribe_atom(id: CId, port: u64) {
  access_store_with(|store| store.subscribe_atom(id.into(), port));
}
#[no_mangle]
pub extern "C" fn unsubscribe_atom(id: CId, port: u64) {
  access_store_with(|store| store.unsubscribe_atom(id.into(), port));
}
#[no_mangle]
pub extern "C" fn subscribe_edge(id: CId, port: u64) {
  access_store_with(|store| store.subscribe_edge(id.into(), port));
}
#[no_mangle]
pub extern "C" fn unsubscribe_edge(id: CId, port: u64) {
  access_store_with(|store| store.unsubscribe_edge(id.into(), port));
}
#[no_mangle]
pub extern "C" fn subscribe_multiedge(src: CId, label: u64, port: u64) {
  access_store_with(|store| store.subscribe_multiedge(src.into(), label, port));
}
#[no_mangle]
pub extern "C" fn unsubscribe_multiedge(src: CId, label: u64, port: u64) {
  access_store_with(|store| store.unsubscribe_multiedge(src.into(), label, port));
}
#[no_mangle]
pub extern "C" fn subscribe_backedge(src: CId, label: u64, port: u64) {
  access_store_with(|store| store.subscribe_backedge(src.into(), label, port));
}
#[no_mangle]
pub extern "C" fn unsubscribe_backedge(src: CId, label: u64, port: u64) {
  access_store_with(|store| store.unsubscribe_backedge(src.into(), label, port));
}

#[no_mangle]
pub extern "C" fn sync_version() -> CArray<u8> {
  CArray::from_leaked(access_store_with(|store| store.sync_version()))
}
#[no_mangle]
pub extern "C" fn sync_actions(version: CArray<u8>) -> CArray<u8> {
  CArray::from_leaked(access_store_with(|store| store.sync_actions(version.as_ref_unchecked())))
}
#[no_mangle]
pub extern "C" fn sync_join(actions: CArray<u8>) {
  access_store_with(|store| store.sync_join(actions.as_ref_unchecked()))
}

#[no_mangle]
pub extern "C" fn poll_events() -> CArray<CPair<u64, CEventData>> {
  let boxed = access_store_with(|store| store.poll_events())
    .into_iter()
    .map(|(port, data)| CPair { first: port, second: data })
    .collect();
  CArray::from_leaked(boxed)
}

#[no_mangle]
pub extern "C" fn drop_array_u8(array: CArray<u8>) {
  array.drop()
}
#[no_mangle]
pub extern "C" fn drop_array_id_edge(array: CArray<CPair<CId, CEdge>>) {
  array.drop()
}
#[no_mangle]
pub extern "C" fn drop_array_id_id(array: CArray<CPair<CId, CId>>) {
  array.drop()
}
#[no_mangle]
pub extern "C" fn drop_array_u64_event_data(array: CArray<CPair<u64, CEventData>>) {
  array.drop()
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
    export_symbol!(fn hash(name: *const i8) -> u64);
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
    export_symbol!(fn subscribe_backedge(src: CId, label: u64, port: u64));
    export_symbol!(fn unsubscribe_backedge(src: CId, label: u64, port: u64));

    export_symbol!(fn sync_version() -> CArray<u8>);
    export_symbol!(fn sync_actions(version: CArray<u8>) -> CArray<u8>);
    export_symbol!(fn sync_join(actions: CArray<u8>));
    export_symbol!(fn poll_events() -> CArray<CPair<u64, CEventData>>);
  };
}
