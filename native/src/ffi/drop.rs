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

use super::*;

/// Drops the return value of [`node_id_by_label`].
#[no_mangle]
pub unsafe extern "C" fn dust_drop_array_id(value: CArray<CId>) {
  value.into_boxed();
}

/// Drops the return value of [`atom`].
#[no_mangle]
pub unsafe extern "C" fn dust_drop_option_atom(value: COption<CAtom>) {
  if let COption::Some(inner) = value {
    inner.value.as_ref();
  }
}

/// Drops the return value of [`atom_id_label_value_by_src`].
#[no_mangle]
pub unsafe extern "C" fn dust_drop_array_id_u64_array_u8(value: CArray<CTriple<CId, u64, CArray<u8>>>) {
  for elem in value.into_boxed().into_vec().into_iter() {
    elem.2.into_boxed();
  }
}

/// Drops the return value of [`atom_id_value_by_src_label`].
#[no_mangle]
pub unsafe extern "C" fn dust_drop_array_id_array_u8(value: CArray<CPair<CId, CArray<u8>>>) {
  for elem in value.into_boxed().into_vec().into_iter() {
    elem.1.into_boxed();
  }
}

/// Drops the return value of [`atom_id_src_value_by_label`].
#[no_mangle]
pub unsafe extern "C" fn dust_drop_array_id_id_array_u8(value: CArray<CTriple<CId, CId, CArray<u8>>>) {
  for elem in value.into_boxed().into_vec().into_iter() {
    elem.2.into_boxed();
  }
}

/// Drops the return value of [`atom_id_src_by_label_value`], [`edge_id_dst_by_src_label`] and [`edge_id_src_by_dst_label`].
#[no_mangle]
pub unsafe extern "C" fn dust_drop_array_id_id(value: CArray<CPair<CId, CId>>) {
  value.into_boxed();
}

/// Drops the return value of [`edge_id_label_dst_by_src`].
#[no_mangle]
pub unsafe extern "C" fn dust_drop_array_id_u64_id(value: CArray<CTriple<CId, u64, CId>>) {
  value.into_boxed();
}

/// Drops the return value of [`edge_id_src_label_by_dst`].
#[no_mangle]
pub unsafe extern "C" fn dust_drop_array_id_id_u64(value: CArray<CTriple<CId, CId, u64>>) {
  value.into_boxed();
}

/// Drops the return value of [`sync_version`] and [`sync_actions`] and all error results.
#[no_mangle]
pub unsafe extern "C" fn dust_drop_array_u8(value: CArray<u8>) {
  value.into_boxed();
}

/// Drops the return value of [`barrier`].
#[no_mangle]
pub unsafe extern "C" fn dust_drop_array_event_data(value: CArray<CEventData>) {
  for elem in value.into_boxed().into_vec().into_iter() {
    if let CEventData::Atom { id: _, prev, curr } = elem {
      if let COption::Some(inner) = prev {
        inner.value.into_boxed();
      }
      if let COption::Some(inner) = curr {
        inner.value.into_boxed();
      }
    }
  }
}
