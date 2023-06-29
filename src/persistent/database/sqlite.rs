//! A thin wrapper for `rusqlite`, assuming everything is stored as `BLOB`s.
//!
//! See: https://www.sqlite.org/queryplanner.html
//! See: https://www.sqlite.org/optoverview.html
//! See: https://www.sqlite.org/queryplanner-ng.html

use rusqlite::{params_from_iter, Connection, OptionalExtension, TransactionBehavior};

use super::{Database, Order, Select, Table, Transaction};

/// The row ID type.
type SqliteRowId = i64;

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

pub struct SqliteDatabase {
  conn: Connection,
}

impl SqliteDatabase {
  pub fn open(path: &str) -> Self {
    let conn = Connection::open(path).unwrap();
    conn.execute_batch(INITIAL_COMMANDS).unwrap();
    Self { conn }
  }
  pub fn open_in_memory() -> Self {
    let conn = Connection::open_in_memory().unwrap();
    conn.execute_batch(INITIAL_COMMANDS).unwrap();
    Self { conn }
  }
  pub fn close(self) {
    self.conn.close().unwrap();
  }
}

impl Database for SqliteDatabase {
  type RowId = SqliteRowId;
  type Transaction<'a> = SqliteTransaction<'a>;
  type Table<const N: usize, const M: usize> = SqliteTable<N, M>;
  type Select<'a, const N: usize, const M: usize> = SqliteSelect<'a, N, M>;

  fn transaction(&mut self) -> SqliteTransaction {
    let transaction = self.conn.transaction_with_behavior(TransactionBehavior::Immediate).unwrap();
    SqliteTransaction { inner: transaction }
  }
  fn table<const N: usize, const M: usize>(
    &self,
    name: &'static str,
    columns: [&'static str; N],
    indices: [(&'static str, &'static [usize]); M],
  ) -> SqliteTable<N, M> {
    debug_assert!(!columns.is_empty());
    let definition = columns.map(|column_name| format!("{column_name} BLOB NOT NULL")).join(", ");
    self.conn.execute_batch(&format!("CREATE TABLE IF NOT EXISTS {name} ({definition}) STRICT")).unwrap();
    for (index_name, index_columns) in indices {
      debug_assert!(!index_columns.is_empty());
      let columns = index_columns.iter().copied().map(|c| columns[c]).collect::<Vec<_>>().join(", ");
      self.conn.execute_batch(&format!("CREATE INDEX IF NOT EXISTS {index_name} ON {name} ({columns})")).unwrap();
    }
    SqliteTable { name, columns, indices }
  }
}

pub struct SqliteTable<const N: usize, const M: usize> {
  name: &'static str,
  columns: [&'static str; N],
  indices: [(&'static str, &'static [usize]); M],
}

impl<const N: usize, const M: usize> Table<SqliteDatabase, N, M> for SqliteTable<N, M> {
  fn name(&self) -> &str {
    self.name
  }
  fn columns(&self) -> [&str; N] {
    self.columns
  }
  fn indices(&self) -> [(&str, &[usize]); M] {
    self.indices
  }
}

pub struct SqliteTransaction<'a> {
  inner: rusqlite::Transaction<'a>,
}

impl<'a> Transaction<'a, SqliteDatabase> for SqliteTransaction<'a> {
  fn select<const N: usize, const M: usize>(&'a self, table: &'a SqliteTable<N, M>) -> SqliteSelect<'a, N, M> {
    SqliteSelect { transaction: &self.inner, table }
  }
  fn commit(self) {
    self.inner.commit().unwrap_or_else(|_| panic!("failed to commit transaction"));
  }
  fn discard(self) {
    self.inner.rollback().unwrap_or_else(|_| panic!("failed to discard transaction"));
  }
}

pub struct SqliteSelect<'a, const N: usize, const M: usize> {
  transaction: &'a rusqlite::Transaction<'a>,
  table: &'a SqliteTable<N, M>,
}

impl<'a, const N: usize, const M: usize> Select<'a, SqliteDatabase, N, M> for SqliteSelect<'a, N, M> {
  fn put(&self, values: [&[u8]; N]) -> SqliteRowId {
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

  fn get(&self, id: SqliteRowId) -> [Vec<u8>; N] {
    let table_name = self.table.name;
    let column_names = self.table.columns.join(", ");
    self
      .transaction
      .prepare_cached(&format!("SELECT {column_names} FROM {table_name} WHERE {ROWID} = ?"))
      .unwrap()
      .query_row([id], |row| Ok(self.table.columns.map(|name| row.get_unwrap(name))))
      .unwrap()
  }

  fn set(&self, id: SqliteRowId, values: [&[u8]; N]) {
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

  fn del(&self, id: SqliteRowId) -> bool {
    let table_name = self.table.name;
    self
      .transaction
      .prepare_cached(&format!("DELETE FROM {table_name} WHERE {ROWID} = ?"))
      .unwrap()
      .execute([id])
      .unwrap()
      != 0
  }

  fn query_any<const K: usize>(&self, index: usize, values: [&[u8]; K]) -> Option<(SqliteRowId, [Vec<u8>; N])> {
    debug_assert!(K <= self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let mut where_clause = String::new();
    for i in 0..K {
      where_clause.push_str(if where_clause.is_empty() { "WHERE " } else { " AND " });
      where_clause.push_str(self.table.columns[self.table.indices[index].1[i]]);
      where_clause.push_str(" = ?");
    }
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

  fn query_all<const K: usize>(&self, index: usize, values: [&[u8]; K]) -> Vec<(SqliteRowId, [Vec<u8>; N])> {
    debug_assert!(K <= self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let mut where_clause = String::new();
    for i in 0..K {
      where_clause.push_str(if where_clause.is_empty() { "WHERE " } else { " AND " });
      where_clause.push_str(self.table.columns[self.table.indices[index].1[i]]);
      where_clause.push_str(" = ?");
    }
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

  fn query_sorted_first<const K: usize>(
    &self,
    index: usize,
    values: [&[u8]; K],
    order: Order,
  ) -> Option<(SqliteRowId, [Vec<u8>; N])> {
    debug_assert!(K < self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let mut where_clause = String::new();
    for i in 0..K {
      where_clause.push_str(if where_clause.is_empty() { "WHERE " } else { " AND " });
      where_clause.push_str(self.table.columns[self.table.indices[index].1[i]]);
      where_clause.push_str(" = ?");
    }
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

  fn query_sorted_range<const K: usize>(
    &self,
    index: usize,
    values: [&[u8]; K],
    order: Order,
    lower: Option<&[u8]>,
    upper: Option<&[u8]>,
  ) -> Vec<(SqliteRowId, [Vec<u8>; N])> {
    debug_assert!(K < self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let mut where_clause = String::new();
    let mut values_vec: Vec<_> = values.into_iter().collect();
    for i in 0..K {
      where_clause.push_str(if where_clause.is_empty() { "WHERE " } else { " AND " });
      where_clause.push_str(self.table.columns[self.table.indices[index].1[i]]);
      where_clause.push_str(" = ?");
    }
    let sort_column = self.table.columns[self.table.indices[index].1[K]];
    let sort_order = match order {
      Order::Asc => "ASC",
      Order::Desc => "DESC",
    };
    if let Some(lower) = lower {
      where_clause.push_str(if where_clause.is_empty() { "WHERE " } else { " AND " });
      where_clause.push_str(sort_column);
      where_clause.push_str(" >= ?");
      values_vec.push(lower);
    }
    if let Some(upper) = upper {
      where_clause.push_str(if where_clause.is_empty() { "WHERE " } else { " AND " });
      where_clause.push_str(sort_column);
      where_clause.push_str(" <= ?");
      values_vec.push(upper);
    }
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

  fn query_sorted_count<const K: usize>(
    &self,
    index: usize,
    values: [&[u8]; K],
    order: Order,
    start: Option<i64>,
    count: Option<i64>,
  ) -> Vec<(SqliteRowId, [Vec<u8>; N])> {
    debug_assert!(K < self.table.indices[index].1.len());
    let column_names = self.table.columns.join(", ");
    let table_name = self.table.name;
    let index_name = self.table.indices[index].0;
    let mut where_clause = String::new();
    for i in 0..K {
      where_clause.push_str(if where_clause.is_empty() { "WHERE " } else { " AND " });
      where_clause.push_str(self.table.columns[self.table.indices[index].1[i]]);
      where_clause.push_str(" = ?");
    }
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
