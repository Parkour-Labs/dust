pub trait ValueStore<V> {
  fn get(&mut self) -> Option<V>;
  fn set(&mut self, value: Option<&V>);
}

pub trait KeyValueStore<K, V> {
  fn get(&mut self, key: K) -> Option<V>;
  fn set(&mut self, key: K, value: Option<&V>);
}

pub trait KeyIndexValueStore<K, I, V>: KeyValueStore<K, (I, V)> {
  fn get_by_index(&mut self, index: I) -> Vec<(K, (I, V))>;
}

pub trait KeyBiIndexValueStore<K, I1, I2, V>: KeyValueStore<K, (I1, I2, V)> {
  fn get_by_index_1(&mut self, index: I1) -> Vec<(K, (I1, I2, V))>;
  fn get_by_index_2(&mut self, index: I2) -> Vec<(K, (I1, I2, V))>;
}

// Transactions might be needed in far future (OT strategies have atomicity requirements).
