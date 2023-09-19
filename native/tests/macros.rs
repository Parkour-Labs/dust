/*
use beacons::global::{self, Atom, AtomOption, Backlinks, Link, LinkOption, Model, Multilinks};
use beacons::model;

#[derive(Debug)]
#[model]
struct Trivial;

#[derive(Debug)]
#[model]
struct Something {
  atom_one: Atom<String>,
  atom_two: AtomOption<String>,
  link_one: Link<Trivial>,
  link_two: LinkOption<Trivial>,
  link_three: Multilinks<Something>,
  #[backlink(link_three)]
  backlink: Backlinks<Something>,
}

#[test]
fn atom_link_simple() {
  global::init_in_memory();

  let trivial = Trivial::new();
  let trivial_again = Trivial::new();

  let something = Something::new(&String::from("test"), Some(&String::from("2333")), &trivial, Some(&trivial));
  let something_else = Something::new(&String::from("test"), None, &trivial, None);
  something_else.link_three.insert(&something);

  let something_id = something.id();
  let something_else_id = something_else.id();

  let something_copy = Something::get(something_id).unwrap();
  let something_else_copy = Something::get(something_else_id).unwrap();

  assert_eq!(something_copy.atom_one.get(), "test");
  assert_eq!(something_copy.atom_two.get().unwrap(), "2333");
  assert_eq!(something_copy.link_one.get().id(), trivial.id());
  assert_eq!(something_copy.link_two.get().unwrap().id(), trivial.id());
  assert_eq!(something_copy.link_three.get().len(), 0);

  assert_eq!(something_else_copy.atom_one.get(), "test");
  assert!(something_else_copy.atom_two.get().is_none());
  assert_eq!(something_else_copy.link_one.get().id(), trivial.id());
  assert!(something_else_copy.link_two.get().is_none());
  assert_eq!(something_else_copy.link_three.get().len(), 1);
  assert_eq!(something_else_copy.link_three.get()[0].id(), something.id());

  something_copy.atom_two.set(None);
  assert!(something_copy.atom_two.get().is_none());
  something_copy.atom_two.set(Some(&String::from("gg")));
  assert_eq!(something_copy.atom_two.get().unwrap(), "gg");
  something_copy.link_two.set(None);
  assert!(something_copy.link_two.get().is_none());
  something_copy.link_two.set(Some(&trivial_again));
  assert_eq!(something_copy.link_two.get().unwrap().id(), trivial_again.id());

  assert_eq!(something.backlink.get().len(), 1);
  something.link_three.insert(&something);
  assert_eq!(something.backlink.get().len(), 2);
  something.link_three.insert(&something);
  assert_eq!(something.backlink.get().len(), 3);
  something.link_three.remove(&something);
  assert_eq!(something.backlink.get().len(), 2);
  something_else.link_three.remove(&something);
  assert_eq!(something.backlink.get().len(), 1);

  trivial.delete();
  trivial_again.delete();
  assert!(std::panic::catch_unwind(|| something.link_one.get()).is_err()); // Panics.
  assert!(something.link_two.get().is_none());
  assert!(std::panic::catch_unwind(|| something_else.link_one.get()).is_err()); // Panics.
  assert!(something_else.link_two.get().is_none());
  something.delete();
  something_else.delete();
}
*/
