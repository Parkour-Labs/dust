//! TODO: remove

use std::sync::mpsc;

pub mod joinable;
pub mod observable;
pub mod persistent;

pub fn add(left: usize, right: usize) -> usize {
  left + right
}

pub fn function() {
  let (tx, rx) = mpsc::channel();
  let _result1 = tx.send("hi");
  let _result2 = rx.recv();
}
