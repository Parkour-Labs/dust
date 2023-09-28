use super::*;

/// Drops the return value of [`node_id_by_label`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id(value: CArray<CId>) {
  value.into_boxed();
}

/// Drops the return value of [`atom`].
#[no_mangle]
pub unsafe extern "C" fn drop_option_atom(value: COption<CAtom>) {
  if let COption::Some(inner) = value {
    inner.value.as_ref();
  }
}

/// Drops the return value of [`atom_id_label_value_by_src`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_u64_array_u8(value: CArray<CTriple<CId, u64, CArray<u8>>>) {
  for elem in value.into_boxed().into_vec().into_iter() {
    elem.2.into_boxed();
  }
}

/// Drops the return value of [`atom_id_value_by_src_label`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_array_u8(value: CArray<CPair<CId, CArray<u8>>>) {
  for elem in value.into_boxed().into_vec().into_iter() {
    elem.1.into_boxed();
  }
}

/// Drops the return value of [`atom_id_src_value_by_label`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_id_array_u8(value: CArray<CTriple<CId, CId, CArray<u8>>>) {
  for elem in value.into_boxed().into_vec().into_iter() {
    elem.2.into_boxed();
  }
}

/// Drops the return value of [`atom_id_src_by_label_value`], [`edge_id_dst_by_src_label`] and [`edge_id_src_by_dst_label`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_id(value: CArray<CPair<CId, CId>>) {
  value.into_boxed();
}

/// Drops the return value of [`edge_id_label_dst_by_src`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_u64_id(value: CArray<CTriple<CId, u64, CId>>) {
  value.into_boxed();
}

/// Drops the return value of [`edge_id_src_label_by_dst`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_id_id_u64(value: CArray<CTriple<CId, CId, u64>>) {
  value.into_boxed();
}

/// Drops the return value of [`sync_version`] and [`sync_actions`] and all error results.
#[no_mangle]
pub unsafe extern "C" fn drop_array_u8(value: CArray<u8>) {
  value.into_boxed();
}

/// Drops the return value of [`barrier`].
#[no_mangle]
pub unsafe extern "C" fn drop_array_event_data(value: CArray<CEventData>) {
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
