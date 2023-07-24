use std::hash::Hash;

pub mod sqlite;

#[cfg(test)]
mod tests;

/// Sort order.
pub enum Order {
  Asc,
  Desc,
}

/// A database connection.
pub trait Database {
  /// Currently we consider all tables to have the same primary key type.
  type RowId: Copy + Eq + Hash;
  /// Currently we consider exclusive transactions only.
  type Transaction<'a>: Transaction<'a, Self>
  where
    Self: 'a;
  /// Associated table type.
  type Table<const N: usize, const M: usize>: Table<Self, N, M>;
  /// Associated selection type.
  type Select<'a, const N: usize, const M: usize>: Select<'a, Self, N, M>
  where
    Self: 'a;

  /// Starts a transaction.
  fn transaction(&mut self) -> Self::Transaction<'_>;
  /// Initialises a table.
  fn table<const N: usize, const M: usize>(
    &self,
    name: &'static str,
    columns: [&'static str; N],
    indices: [(&'static str, &'static [usize]); M],
  ) -> Self::Table<N, M>;
}

/// An exclusive transaction.
pub trait Transaction<'a, T: Database + ?Sized> {
  /// Selects a table.
  fn select<const N: usize, const M: usize>(&'a self, table: &'a T::Table<N, M>) -> T::Select<'a, N, M>;
  /// Persists and drops transaction.
  fn commit(self);
  /// Discards and drops transaction.
  fn discard(self);
}

/// A table schema with `N` columns and `M` indices.
pub trait Table<T: Database + ?Sized, const N: usize, const M: usize> {
  /// Retrieves table name.
  fn name(&self) -> &str;
  /// Retrieves column names.
  fn columns(&self) -> [&str; N];
  /// Retrieves index names.
  fn indices(&self) -> [(&str, &[usize]); M];
}

/// A selection on a table with `N` columns and `M` indices.
pub trait Select<'a, T: Database + ?Sized, const N: usize, const M: usize> {
  /// Creates new object with an automatically-assigned row ID.
  fn put(&self, values: [&[u8]; N]) -> T::RowId;
  /// Retrieves object by row ID.
  fn get(&self, id: T::RowId) -> [Vec<u8>; N];
  /// Creates or overrides object by row ID.
  fn set(&self, id: T::RowId, values: [&[u8]; N]);
  /// Deletes object by row ID.
  fn del(&self, id: T::RowId) -> bool;
  /// Returns an arbitrary object matching equality constraints, if one exists (index required).
  fn query_any<const K: usize>(&self, index: usize, values: [&[u8]; K]) -> Option<(T::RowId, [Vec<u8>; N])>;
  /// Returns all objects matching equality constraints (index required).
  fn query_all<const K: usize>(&self, index: usize, values: [&[u8]; K]) -> Vec<(T::RowId, [Vec<u8>; N])>;
  /// Returns the first object matching equality constaints (index required).
  fn query_sorted_first<const K: usize>(
    &self,
    index: usize,
    values: [&[u8]; K],
    order: Order,
  ) -> Option<(T::RowId, [Vec<u8>; N])>;
  /// Returns all objects matching equality constraints and one inequality constraint (index required).
  fn query_sorted_range<const K: usize>(
    &self,
    index: usize,
    values: [&[u8]; K],
    order: Order,
    lower: Option<&[u8]>,
    upper: Option<&[u8]>,
  ) -> Vec<(T::RowId, [Vec<u8>; N])>;
  /// Returns a specified number of objects matching equality constaints (index required).
  fn query_sorted_count<const K: usize>(
    &self,
    index: usize,
    values: [&[u8]; K],
    order: Order,
    start: Option<i64>,
    count: Option<i64>,
  ) -> Vec<(T::RowId, [Vec<u8>; N])>;
}
