// Copyright 2024 ParkourLabs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#![allow(clippy::missing_safety_doc)]

pub mod drop;
pub mod store;
pub mod structs;

use rusqlite::Connection;
use std::cell::RefCell;

use self::structs::{CArray, CAtom, CEdge, CEventData, CId, CNode, COption, CPair, CResult, CTriple, CUnit};
use crate::{
  store::Store,
  workspace::{Constraints, Workspace},
  StoreError, Transactor,
};

thread_local! {
  static CONSTRAINTS: RefCell<Constraints> = RefCell::new(Constraints::new());
  static STORE: RefCell<Option<Store>> = RefCell::new(None);
}

pub fn convert_result<T>(f: impl FnOnce() -> Result<T, StoreError>) -> CResult<T> {
  f().map_err(|err| err.to_string()).into()
}

pub fn access_workspace<T>(f: impl FnOnce(&mut Transactor, &mut Workspace) -> Result<T, StoreError>) -> CResult<T> {
  STORE
    .with(|cell| {
      let mut borrow = cell.borrow_mut();
      let store = borrow.as_mut().ok_or(StoreError::Uninitialised)?;
      let (txr, ws) = store.as_mut()?;
      f(txr, ws)
    })
    .map_err(|err| err.to_string())
    .into()
}

#[no_mangle]
pub extern "C" fn dust_add_sticky_node(label: u64) {
  CONSTRAINTS.with(|cell| cell.borrow_mut().add_sticky_node(label));
}

#[no_mangle]
pub extern "C" fn dust_add_sticky_atom(label: u64) {
  CONSTRAINTS.with(|cell| cell.borrow_mut().add_sticky_atom(label));
}

#[no_mangle]
pub extern "C" fn dust_add_sticky_edge(label: u64) {
  CONSTRAINTS.with(|cell| cell.borrow_mut().add_sticky_edge(label));
}

#[no_mangle]
pub extern "C" fn dust_add_acyclic_edge(label: u64) {
  CONSTRAINTS.with(|cell| cell.borrow_mut().add_acyclic_edge(label));
}

#[no_mangle]
pub unsafe extern "C" fn dust_open(len: u64, ptr: *mut u8) -> CResult<CUnit> {
  convert_result(|| {
    if STORE.with(|cell| cell.borrow().is_some()) {
      // FIXME: This is a hack to avoid double-initialisation in flutter's hot reload, but this will
      // cause new databases unable to be opened.
      return Ok(CUnit(0));
    }
    let path = CArray(len, ptr).as_ref();
    let path = std::str::from_utf8(path).map_err(|_| StoreError::InvalidUtf8)?;
    let conn = Connection::open(path)?;
    conn.execute_batch(
      "
      PRAGMA auto_vacuum = INCREMENTAL;
      PRAGMA journal_mode = WAL;
      PRAGMA synchronous = NORMAL;
      PRAGMA wal_autocheckpoint = 2000;
      PRAGMA cache_size = 2000;
      PRAGMA busy_timeout = 1000;
      ",
    )?;
    let store = Store::new(conn, CONSTRAINTS.with(|cell| cell.borrow().clone()))?;
    STORE.with(|cell| cell.replace(Some(store)));
    Ok(CUnit(0))
  })
}

#[no_mangle]
pub extern "C" fn dust_commit() -> CResult<CUnit> {
  convert_result(|| {
    STORE.with(|cell| {
      cell.borrow_mut().as_mut().ok_or(StoreError::Uninitialised)?.commit()?;
      Ok(CUnit(0))
    })
  })
}

#[no_mangle]
pub extern "C" fn dust_close() -> CResult<CUnit> {
  convert_result(|| {
    STORE.with(|cell| cell.take()).ok_or(StoreError::Uninitialised)?.close()?;
    Ok(CUnit(0))
  })
}
