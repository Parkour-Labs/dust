use rand::Rng;

use super::*;

#[no_mangle]
pub extern "C" fn random_id() -> CId {
  rand::thread_rng().gen::<u128>().into()
}

#[no_mangle]
pub extern "C" fn node(idh: u64, idl: u64) -> CResult<COption<CNode>> {
  access_workspace(|txr, ws| {
    let id = CId(idh, idl).into();
    Ok(ws.node(txr, id).map(Into::into).into())
  })
}

#[no_mangle]
pub extern "C" fn node_id_by_label(label: u64) -> CResult<CArray<CId>> {
  access_workspace(|txr, ws| {
    Ok(ws.node_id_by_label(txr, label).into_keys().map(|id| id.into()).collect::<Box<[_]>>().into())
  })
}

#[no_mangle]
pub extern "C" fn atom(idh: u64, idl: u64) -> CResult<COption<CAtom>> {
  access_workspace(|txr, ws| {
    let id = CId(idh, idl).into();
    Ok(ws.atom(txr, id).map(Into::into).into())
  })
}

#[no_mangle]
pub extern "C" fn atom_id_label_value_by_src(srch: u64, srcl: u64) -> CResult<CArray<CTriple<CId, u64, CArray<u8>>>> {
  access_workspace(|txr, ws| {
    let src = CId(srch, srcl).into();
    Ok(
      ws.atom_id_label_value_by_src(txr, src)
        .into_iter()
        .map(|(id, (label, value))| CTriple(id.into(), label, value.into()))
        .collect::<Box<[_]>>()
        .into(),
    )
  })
}

#[no_mangle]
pub extern "C" fn atom_id_value_by_src_label(
  srch: u64,
  srcl: u64,
  label: u64,
) -> CResult<CArray<CPair<CId, CArray<u8>>>> {
  access_workspace(|txr, ws| {
    let src = CId(srch, srcl).into();
    Ok(
      ws.atom_id_value_by_src_label(txr, src, label)
        .into_iter()
        .map(|(id, value)| CPair(id.into(), value.into()))
        .collect::<Box<[_]>>()
        .into(),
    )
  })
}

#[no_mangle]
pub extern "C" fn atom_id_src_value_by_label(label: u64) -> CResult<CArray<CTriple<CId, CId, CArray<u8>>>> {
  access_workspace(|txr, ws| {
    Ok(
      ws.atom_id_src_value_by_label(txr, label)
        .into_iter()
        .map(|(id, (src, value))| CTriple(id.into(), src.into(), value.into()))
        .collect::<Box<[_]>>()
        .into(),
    )
  })
}

#[no_mangle]
pub unsafe extern "C" fn atom_id_src_by_label_value(
  label: u64,
  len: u64,
  ptr: *mut u8,
) -> CResult<CArray<CPair<CId, CId>>> {
  access_workspace(|txr, ws| {
    let value = CArray(len, ptr).as_ref();
    Ok(
      ws.atom_id_src_by_label_value(txr, label, value)
        .into_iter()
        .map(|(id, src)| CPair(id.into(), src.into()))
        .collect::<Box<[_]>>()
        .into(),
    )
  })
}

#[no_mangle]
pub extern "C" fn edge(idh: u64, idl: u64) -> CResult<COption<CEdge>> {
  access_workspace(|txr, ws| {
    let id = CId(idh, idl).into();
    Ok(ws.edge(txr, id).map(Into::into).into())
  })
}

#[no_mangle]
pub extern "C" fn edge_id_label_dst_by_src(srch: u64, srcl: u64) -> CResult<CArray<CTriple<CId, u64, CId>>> {
  access_workspace(|txr, ws| {
    let src = CId(srch, srcl).into();
    Ok(
      ws.edge_id_label_dst_by_src(txr, src)
        .into_iter()
        .map(|(id, (label, dst))| CTriple(id.into(), label, dst.into()))
        .collect::<Box<[_]>>()
        .into(),
    )
  })
}

#[no_mangle]
pub extern "C" fn edge_id_dst_by_src_label(srch: u64, srcl: u64, label: u64) -> CResult<CArray<CPair<CId, CId>>> {
  access_workspace(|txr, ws| {
    let src = CId(srch, srcl).into();
    Ok(
      ws.edge_id_dst_by_src_label(txr, src, label)
        .into_iter()
        .map(|(id, dst)| CPair(id.into(), dst.into()))
        .collect::<Box<[_]>>()
        .into(),
    )
  })
}

#[no_mangle]
pub extern "C" fn edge_id_src_label_by_dst(dsth: u64, dstl: u64) -> CResult<CArray<CTriple<CId, CId, u64>>> {
  access_workspace(|txr, ws| {
    let dst = CId(dsth, dstl).into();
    Ok(
      ws.edge_id_src_label_by_dst(txr, dst)
        .into_iter()
        .map(|(id, (src, label))| CTriple(id.into(), src.into(), label))
        .collect::<Box<[_]>>()
        .into(),
    )
  })
}

#[no_mangle]
pub extern "C" fn edge_id_src_by_dst_label(dsth: u64, dstl: u64, label: u64) -> CResult<CArray<CPair<CId, CId>>> {
  access_workspace(|txr, ws| {
    let dst = CId(dsth, dstl).into();
    Ok(
      ws.edge_id_src_by_dst_label(txr, dst, label)
        .into_iter()
        .map(|(id, src)| CPair(id.into(), src.into()))
        .collect::<Box<[_]>>()
        .into(),
    )
  })
}

#[no_mangle]
pub extern "C" fn set_node_none(idh: u64, idl: u64) -> CResult<CUnit> {
  access_workspace(|txr, ws| {
    let id = CId(idh, idl).into();
    ws.set_node(txr, id, None);
    Ok(CUnit(0))
  })
}

#[no_mangle]
pub extern "C" fn set_node_some(idh: u64, idl: u64, label: u64) -> CResult<CUnit> {
  access_workspace(|txr, ws| {
    let id = CId(idh, idl).into();
    ws.set_node(txr, id, Some(label));
    Ok(CUnit(0))
  })
}

#[no_mangle]
pub extern "C" fn set_atom_none(idh: u64, idl: u64) -> CResult<CUnit> {
  access_workspace(|txr, ws| {
    let id = CId(idh, idl).into();
    ws.set_atom(txr, id, None);
    Ok(CUnit(0))
  })
}

#[no_mangle]
pub unsafe extern "C" fn set_atom_some(
  idh: u64,
  idl: u64,
  srch: u64,
  srcl: u64,
  label: u64,
  len: u64,
  ptr: *mut u8,
) -> CResult<CUnit> {
  access_workspace(|txr, ws| {
    let id = CId(idh, idl).into();
    let src = CId(srch, srcl).into();
    let value = CArray(len, ptr).as_ref();
    ws.set_atom(txr, id, Some((src, label, Vec::from(value).into())));
    Ok(CUnit(0))
  })
}

#[no_mangle]
pub extern "C" fn set_edge_none(idh: u64, idl: u64) -> CResult<CUnit> {
  access_workspace(|txr, ws| {
    let id = CId(idh, idl).into();
    ws.set_edge(txr, id, None);
    Ok(CUnit(0))
  })
}

#[no_mangle]
pub extern "C" fn set_edge_some(
  idh: u64,
  idl: u64,
  srch: u64,
  srcl: u64,
  label: u64,
  dsth: u64,
  dstl: u64,
) -> CResult<CUnit> {
  access_workspace(|txr, ws| {
    let id = CId(idh, idl).into();
    let src = CId(srch, srcl).into();
    let dst = CId(dsth, dstl).into();
    ws.set_edge(txr, id, Some((src, label, dst)));
    Ok(CUnit(0))
  })
}

#[no_mangle]
pub extern "C" fn sync_version() -> CResult<CArray<u8>> {
  access_workspace(|txr, ws| Ok(ws.sync_version(txr).into()))
}

#[no_mangle]
pub unsafe extern "C" fn sync_actions(len: u64, ptr: *mut u8) -> CResult<CArray<u8>> {
  access_workspace(|txr, ws| {
    let version = CArray(len, ptr).as_ref();
    Ok(ws.sync_actions(txr, version).into())
  })
}

#[no_mangle]
pub unsafe extern "C" fn sync_join(len: u64, ptr: *mut u8) -> CResult<CUnit> {
  access_workspace(|txr, ws| {
    let actions = CArray(len, ptr).as_ref();
    ws.sync_join(txr, actions);
    Ok(CUnit(0))
  })
}

#[no_mangle]
pub extern "C" fn barrier() -> CResult<CArray<CEventData>> {
  access_workspace(|txr, ws| Ok(ws.barrier(txr).into()))
}
