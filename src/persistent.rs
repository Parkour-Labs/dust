pub mod controller;
pub mod store;
pub mod vector_history;

#[cfg(test)]
mod tests;

pub trait Persistent<Store> {
  fn attach(store: Store) -> Self;
  fn save(&mut self);
  fn set_auto_save(&mut self, value: bool);
}
