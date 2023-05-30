//! TODO: remove

use std::sync::mpsc;

pub mod joinable;
pub mod persistent;
pub mod reactive;

pub fn add(left: usize, right: usize) -> usize {
  left + right
}

pub fn function() {
  let (tx, rx) = mpsc::channel();
  let _result1 = tx.send("hi");
  let _result2 = rx.recv();
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn it_works() {
    let result = add(2, 2);
    assert_eq!(result, 4);
  }
}
