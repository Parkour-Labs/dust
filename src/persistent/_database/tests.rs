use super::{sqlite::SqliteDatabase, Database, Order, Select, Transaction};

#[test]
fn crud_simple() {
  let mut db = SqliteDatabase::open_in_memory();
  let table = db.table("test", ["a", "b", "c"], []);
  let txn = db.transaction();

  let id = txn.select(&table).put([&[1], &[2], &[3]]);
  assert_eq!(txn.select(&table).get(id), [vec![1], vec![2], vec![3]]);

  txn.select(&table).set(id, [&[4], &[5], &[6]]);
  assert_eq!(txn.select(&table).get(id), [vec![4], vec![5], vec![6]]);

  txn.select(&table).set(id + 1, [&[7], &[8, 8], &[9, 9, 9]]);
  assert_eq!(txn.select(&table).get(id + 1), [vec![7], vec![8, 8], vec![9, 9, 9]]);

  assert!(txn.select(&table).del(id));
  assert!(txn.select(&table).del(id + 1));
  assert!(!txn.select(&table).del(id + 2));

  txn.commit();
}

#[test]
fn indices_simple() {
  let mut db = SqliteDatabase::open_in_memory();
  let table = db.table(
    "test",
    ["a", "b", "c"],
    [
      ("idx_a", &[0]),
      ("idx_b", &[1]),
      ("idx_cb", &[2, 1]),
      ("idx_abc", &[0, 1, 2]),
      ("idx_bac", &[1, 0, 2]),
      ("idx_cab", &[2, 0, 1]),
    ],
  );
  let txn = db.transaction();
  let sel = txn.select(&table);

  let ids = [
    sel.put([&[1], &[1], &[1]]),
    sel.put([&[1], &[1], &[2]]),
    sel.put([&[1], &[2], &[3]]),
    sel.put([&[1], &[2], &[4]]),
    sel.put([&[1], &[3], &[5]]),
    sel.put([&[1], &[3], &[6]]),
    sel.put([&[2], &[1], &[1]]),
    sel.put([&[2], &[1], &[2]]),
    sel.put([&[2], &[2], &[3]]),
    sel.put([&[2], &[2], &[4]]),
    sel.put([&[2], &[3], &[5]]),
    sel.put([&[2], &[3], &[6]]),
  ];

  // Query all.
  assert_eq!(
    sel.query_all(2, [&[6], &[3]]),
    vec![(ids[5], [vec![1], vec![3], vec![6]]), (ids[11], [vec![2], vec![3], vec![6]])]
  );
  assert_eq!(
    sel.query_all(2, [&[6]]),
    vec![(ids[5], [vec![1], vec![3], vec![6]]), (ids[11], [vec![2], vec![3], vec![6]])]
  );

  // Query any.
  assert_eq!(sel.query_any(3, [&[2], &[1], &[1]]).map(|(id, _)| id), Some(ids[6]));
  assert_eq!(sel.query_any(3, [&[2], &[2], &[2]]).map(|(id, _)| id), None);

  // Query first.
  assert_eq!(sel.query_sorted_first(3, [&[2], &[2]], Order::Asc).map(|(id, _)| id), Some(ids[8]));
  assert_eq!(sel.query_sorted_first(3, [&[2], &[2]], Order::Desc).map(|(id, _)| id), Some(ids[9]));

  // Query range.
  assert_eq!(
    sel.query_sorted_range(5, [], Order::Asc, Some(&[2]), Some(&[4])).into_iter().map(|(id, _)| id).collect::<Vec<_>>(),
    vec![ids[1], ids[7], ids[2], ids[8], ids[3], ids[9]]
  );
  assert_eq!(
    sel.query_sorted_range(5, [], Order::Desc, None, Some(&[2])).into_iter().map(|(id, _)| id).collect::<Vec<_>>(),
    vec![ids[7], ids[1], ids[6], ids[0]]
  );
  assert_eq!(
    sel.query_sorted_range(5, [], Order::Asc, Some(&[3]), None).into_iter().map(|(id, _)| id).collect::<Vec<_>>(),
    vec![ids[2], ids[8], ids[3], ids[9], ids[4], ids[10], ids[5], ids[11]]
  );
  assert_eq!(
    sel.query_sorted_range(5, [], Order::Desc, None, None).into_iter().map(|(id, _)| id).collect::<Vec<_>>(),
    vec![ids[11], ids[5], ids[10], ids[4], ids[9], ids[3], ids[8], ids[2], ids[7], ids[1], ids[6], ids[0]]
  );

  // Query with limit/offset.
  assert_eq!(
    sel.query_sorted_count(5, [], Order::Asc, None, None).into_iter().map(|(id, _)| id).collect::<Vec<_>>(),
    vec![ids[0], ids[6], ids[1], ids[7], ids[2], ids[8], ids[3], ids[9], ids[4], ids[10], ids[5], ids[11]]
  );
  assert_eq!(
    sel.query_sorted_count(5, [], Order::Desc, Some(5), None).into_iter().map(|(id, _)| id).collect::<Vec<_>>(),
    vec![ids[3], ids[8], ids[2], ids[7], ids[1], ids[6], ids[0]]
  );
  assert_eq!(
    sel.query_sorted_count(5, [], Order::Asc, None, Some(5)).into_iter().map(|(id, _)| id).collect::<Vec<_>>(),
    vec![ids[0], ids[6], ids[1], ids[7], ids[2]]
  );
  assert_eq!(
    sel.query_sorted_count(5, [], Order::Desc, Some(10), Some(3)).into_iter().map(|(id, _)| id).collect::<Vec<_>>(),
    vec![ids[6], ids[0]]
  );

  txn.commit();
}
