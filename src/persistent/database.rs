//! A thin wrapper for `rusqlite`, assuming everything is stored as `BLOB`s.
//!
//! See: https://www.sqlite.org/queryplanner.html
//! See: https://www.sqlite.org/optoverview.html
//! See: https://www.sqlite.org/queryplanner-ng.html

use rusqlite::{params_from_iter, Connection, OptionalExtension, TransactionBehavior};

#[cfg(test)]
mod tests;

/// The row ID type.
pub type RowId = i64;

/// The row ID column name.
const ROWID: &str = "rowid";

/// Commands to be executed at the beginning of a connection.
const INITIAL_COMMANDS: &str = "
PRAGMA auto_vacuum = INCREMENTAL;
PRAGMA journal_mode = WAL;
PRAGMA wal_autocheckpoint = 8000;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = -20000;
PRAGMA busy_timeout = 3000;
";

/// Constructs a `WHERE` clause (including the `WHERE` keyword) from constraints.
fn where_clause<T: Iterator<Item = String>>(items: T) -> String {
  let mut res = String::new();
  for item in items {
    if !res.is_empty() {
      res += " AND ";
    }
    res += item.as_str();
  }
  if !res.is_empty() {
    res = String::from("WHERE ") + res.as_str();
  }
  res
}

/// Sort order.
pub enum Order {
  Asc,
  Desc,
}

/// A database connection.
pub struct Database {
  conn: Connection,
}

impl Database {
  fn new(conn: Connection) -> Self {
    conn.execute_batch(INITIAL_COMMANDS).unwrap_or_else(|_| panic!("failed to execute initialisation sequence"));
    Self { conn }
  }

  pub fn open(path: &str) -> Self {
    let conn = Connection::open(path).unwrap_or_else(|_| panic!("failed to open database at {path}"));
    Self::new(conn)
  }

  pub fn open_in_memory() -> Self {
    let conn = Connection::open_in_memory().unwrap_or_else(|_| panic!("failed to open in-memory database"));
    Self::new(conn)
  }

  pub fn table<const N: usize, const M: usize>(
    &self,
    name: &'static str,
    columns: [&'static str; N],
    indices: [(&'static str, &'static [usize]); M],
  ) -> Table<N, M> {
    debug_assert!(!columns.is_empty());
    let definition = columns.map(|column_name| format!("{column_name} BLOB NOT NULL")).join(", ");
    self.conn.execute_batch(&format!("CREATE TABLE IF NOT EXISTS {name} ({definition}) STRICT")).unwrap();
    for (index_name, index_columns) in indices {
      debug_assert!(!index_columns.is_empty());
      let columns = index_columns.iter().copied().map(|c| columns[c]).collect::<Vec<_>>().join(", ");
      self.conn.execute_batch(&format!("CREATE INDEX IF NOT EXISTS {index_name} ON {name} ({columns})")).unwrap();
    }
    Table { name, columns, indices }
  }

  pub fn transaction(&mut self) -> Transaction {
    let transaction = self
      .conn
      .transaction_with_behavior(TransactionBehavior::Immediate)
      .unwrap_or_else(|_| panic!("failed to start exclusive transaction"));
    Transaction { inner: transaction }
  }

  pub fn close(self) {
    self.conn.close().unwrap_or_else(|_| panic!("failed to close database"));
  }
}

/// A table schema.
pub struct Table<const N: usize, const M: usize> {
  name: &'static str,
  columns: [&'static str; N],
  indices: [(&'static str, &'static [usize]); M],
}

/// A wrapper around [`rusqlite::Transaction`]. Defaults to rollback at drop.
pub struct Transaction<'a> {
  inner: rusqlite::Transaction<'a>,
}

impl<'a> Transaction<'a> {
  pub fn select<const N: usize, const M: usize>(&'a self, table: &'a Table<N, M>) -> Selected<'a, N, M> {
    Selected { transaction: &self.inner, table }
  }

  pub fn commit(self) {
    self.inner.commit().unwrap_or_else(|_| panic!("failed to commit transaction"));
  }

  pub fn discard(self) {
    self.inner.rollback().unwrap_or_else(|_| panic!("failed to discard transaction"));
  }
}

/// A "selected" table.
pub struct Selected<'a, const N: usize, const M: usize> {
  transaction: &'a rusqlite::Transaction<'a>,
  table: &'a Table<N, M>,
}

impl<'a, const N: usize, const M: usize> Selected<'a, N, M> {
  /// Creates new object with an automatically-assigned row ID.
  pub fn put(&self, values: [&[u8]; N]) -> RowId {
    let table_name = self.table.name;
    let column_names = self.table.columns.join(", ");
    let question_marks = ["?"; N].join(", ");
    self
      .transaction
      .prepare_cached(&format!("INSERT INTO {table_name} ({column_names}) VALUES ({question_marks})"))
      .unwrap()
      .insert(params_from_iter(values))
      .unwrap()
  }

  /// Retrieves object by row ID.
  pub fn get(&self, id: RowId) -> [Vec<u8>; N] {
    let table_name = self.table.name;
    let column_names = self.table.columns.join(", ");
    self
      .transaction
      .prepare_cached(&format!("SELECT {column_names} FROM {table_name} WHERE {ROWID} = ?"))
      .unwrap()
      .query_row([id], |row| Ok(self.table.columns.map(|name| row.get_unwrap(name))))
      .unwrap()
  }

  /// Creates or overrides object by row ID.
  pub fn set(&self, id: RowId, values: [&[u8]; N]) {
    let table_name = self.table.name;
    let column_names = self.table.columns.join(", ");
    let question_marks = ["?"; N].join(", ");
    let mut stmt = self
      .transaction
      .prepare_cached(&format!("REPLACE INTO {table_name} ({ROWID}, {column_names}) VALUES (?, {question_marks})"))
      .unwrap();
    // Since `id` has a distinct type than `values`, the only sane way to
    // bind parameters is to use the low-level API:
    stmt.raw_bind_parameter(1, id).unwrap();
    for (i, value) in values.iter().enumerate() {
      stmt.raw_bind_parameter(i + 2, value).unwrap();
    }
    stmt.raw_execute().unwrap();
  }

  /// Deletes object by row ID.
  pub fn del(&self, id: RowId) -> bool {
    let table_name = self.table.name;
    self
      .transaction
      .prepare_cached(&format!("DELETE FROM {table_name} WHERE {ROWID} = ?"))
      .unwrap()
      .execute([id])
      .unwrap()
      != 0
  }

  /// Returns an arbitrary object matching equality constraints, if one exists (index required).
  pub fn query_any<const K: usize>(&self, index: usize, values: [&[u8]; K]) -> Option<(RowId, [Vec<u8>; N])> {
    debug_assert!(K <= self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let where_items = self.table.indices[index].1[0..K].iter().map(|c| format!("{} = ?", self.table.columns[*c]));
    let where_clause = where_clause(where_items);
    self
      .transaction
      .prepare(&format!("SELECT {ROWID}, {column_names} FROM {table_name} INDEXED BY {index_name} {where_clause}"))
      .unwrap()
      .query_row(params_from_iter(values), |row| {
        Ok((row.get_unwrap(ROWID), self.table.columns.map(|name| row.get_unwrap(name))))
      })
      .optional()
      .unwrap()
  }

  /// Returns all objects matching equality constraints (index required).
  pub fn query_all<const K: usize>(&self, index: usize, values: [&[u8]; K]) -> Vec<(RowId, [Vec<u8>; N])> {
    debug_assert!(K <= self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let where_items = self.table.indices[index].1[0..K].iter().map(|c| format!("{} = ?", self.table.columns[*c]));
    let where_clause = where_clause(where_items);
    self
      .transaction
      .prepare(&format!("SELECT {ROWID}, {column_names} FROM {table_name} INDEXED BY {index_name} {where_clause}"))
      .unwrap()
      .query_map(params_from_iter(values), |row| {
        Ok((row.get_unwrap(ROWID), self.table.columns.map(|name| row.get_unwrap(name))))
      })
      .unwrap()
      .map(|elem| elem.unwrap())
      .collect()
  }

  /// Returns the first object matching equality constaints (index required).
  pub fn query_sorted_first<const K: usize>(
    &self,
    index: usize,
    values: [&[u8]; K],
    order: Order,
  ) -> Option<(RowId, [Vec<u8>; N])> {
    debug_assert!(K < self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let where_items = self.table.indices[index].1[0..K].iter().map(|c| format!("{} = ?", self.table.columns[*c]));
    let where_clause = where_clause(where_items);
    let sort_column = self.table.columns[self.table.indices[index].1[K]];
    let sort_order = match order {
      Order::Asc => "ASC",
      Order::Desc => "DESC",
    };
    self
      .transaction
      .prepare(&format!(
        "SELECT {ROWID}, {column_names} FROM {table_name} INDEXED BY {index_name} \
        {where_clause} ORDER BY {sort_column} {sort_order}"
      ))
      .unwrap()
      .query_row(params_from_iter(values), |row| {
        Ok((row.get_unwrap(ROWID), self.table.columns.map(|name| row.get_unwrap(name))))
      })
      .optional()
      .unwrap()
  }

  /// Returns all objects matching equality constraints and one inequality constraint (index required).
  pub fn query_sorted_range<const K: usize>(
    &self,
    index: usize,
    values: [&[u8]; K],
    order: Order,
    lower: Option<&[u8]>,
    upper: Option<&[u8]>,
  ) -> Vec<(RowId, [Vec<u8>; N])> {
    debug_assert!(K < self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let mut where_vec: Vec<_> =
      self.table.indices[index].1[0..K].iter().map(|c| format!("{} = ?", self.table.columns[*c])).collect();
    let mut values_vec: Vec<_> = values.into_iter().collect();
    let sort_column = self.table.columns[self.table.indices[index].1[K]];
    let sort_order = match order {
      Order::Asc => "ASC",
      Order::Desc => "DESC",
    };
    if let Some(lower) = lower {
      where_vec.push(format!("{sort_column} >= ?"));
      values_vec.push(lower);
    }
    if let Some(upper) = upper {
      where_vec.push(format!("{sort_column} < ?"));
      values_vec.push(upper);
    }
    let where_clause = where_clause(where_vec.into_iter());
    self
      .transaction
      .prepare(&format!(
        "SELECT {ROWID}, {column_names} FROM {table_name} INDEXED BY {index_name} \
        {where_clause} ORDER BY {sort_column} {sort_order}"
      ))
      .unwrap()
      .query_map(params_from_iter(values_vec), |row| {
        Ok((row.get_unwrap(ROWID), self.table.columns.map(|name| row.get_unwrap(name))))
      })
      .unwrap()
      .map(|elem| elem.unwrap())
      .collect()
  }

  /// Returns a specified number of objects matching equality constaints (index required).
  pub fn query_sorted_count<const K: usize>(
    &self,
    index: usize,
    values: [&[u8]; K],
    order: Order,
    start: Option<i64>,
    count: Option<i64>,
  ) -> Vec<(RowId, [Vec<u8>; N])> {
    debug_assert!(K < self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let where_items = self.table.indices[index].1[0..K].iter().map(|c| format!("{} = ?", self.table.columns[*c]));
    let where_clause = where_clause(where_items);
    let sort_column = self.table.columns[self.table.indices[index].1[K]];
    let sort_order = match order {
      Order::Asc => "ASC",
      Order::Desc => "DESC",
    };
    let start = start.unwrap_or(0);
    let count = count.unwrap_or(-1);
    self
      .transaction
      .prepare(&format!(
        "SELECT {ROWID}, {column_names} FROM {table_name} INDEXED BY {index_name} \
        {where_clause} ORDER BY {sort_column} {sort_order} LIMIT {count} OFFSET {start}"
      ))
      .unwrap()
      .query_map(params_from_iter(values), |row| {
        Ok((row.get_unwrap(ROWID), self.table.columns.map(|name| row.get_unwrap(name))))
      })
      .unwrap()
      .map(|elem| elem.unwrap())
      .collect()
  }
}
