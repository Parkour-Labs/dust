use super::*;

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
