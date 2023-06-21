pub mod controller;
pub mod store;

pub trait Persistent<Store, Provider> {
  fn load(store: Store, providers: Vec<Provider>) -> Self;
  fn save(&mut self);
  fn sync(&mut self);
  fn set_auto_save(&mut self, value: bool);
  fn set_auto_sync(&mut self, value: bool);
}
