use rand::Rng;

use crate::global::{AtomOption, LinkOption};

use super::global::{self, Atom, Backlinks, Link, Model};

#[derive(Debug)]
struct Trivial {
  id: u128,
}

impl Trivial {
  pub const LABEL: u64 = 0 /* Calculated from fnv64_hash("Trivial") */;

  pub fn create(/* (No code generated here) */) -> Self {
    let mut rng = rand::thread_rng();
    let id = rng.gen();

    global::access_store_with(|store| {
      // Create `Trivial`.
      store.set_node(id, Some(Trivial::LABEL));

      /* (No code generated here) */
    });

    // Return.
    Self::get(id).unwrap()
  }

  pub fn remove(self) {
    global::access_store_with(|store| store.set_node(self.id, None));
  }
}

impl Model for Trivial {
  fn id(&self) -> u128 {
    self.id
  }

  fn get(id: u128) -> Option<Self> {
    global::access_store_with(|store| {
      // Variables for existing data.
      /* (No code generated here) */

      // Load existing data.
      store.node(id)?;
      /* (No code generated here) */

      // Pack together. Fail if a field is not found.
      Some(Self {
        id,
        /* (No code generated here) */
      })
    })
  }
}

#[derive(Debug)]
struct Something {
  id: u128,
  atom_one: Atom<String>,
  atom_two: AtomOption<String>,
  link_one: Link<Trivial>,
  link_two: LinkOption<Trivial>,
  link_three: LinkOption<Something>,
  backlink: Backlinks<Something>,
}

impl Something {
  pub const LABEL: u64 = 1 /* Calculated from fnv64_hash("Something") */;
  pub const ATOM_ONE_LABEL: u64 = 2 /* Calculated from fnv64_hash("Something.atom_one") */;
  pub const ATOM_TWO_LABEL: u64 = 3 /* Calculated from fnv64_hash("Something.atom_two") */;
  pub const LINK_ONE_LABEL: u64 = 4 /* Calculated from fnv64_hash("Something.link_one") */;
  pub const LINK_TWO_LABEL: u64 = 5 /* Calculated from fnv64_hash("Something.link_two") */;
  pub const LINK_THREE_LABEL: u64 = 6 /* Calculated from fnv64_hash("Something.link_three") */;

  pub fn create(
    atom_one: &String,
    atom_two: Option<&String>,
    link_one: &Trivial,
    link_two: Option<&Trivial>,
    link_three: Option<&Something>,
  ) -> Self {
    let mut rng = rand::thread_rng();
    let id = rng.gen();

    global::access_store_with(|store| {
      // Create `Something`.
      store.set_node(id, Some(Something::LABEL));

      // Create `Something.atom_one`.
      let atom_one_id = rng.gen();
      store.set_edge(rng.gen(), Some((id, Something::ATOM_ONE_LABEL, atom_one_id)));
      store.set_atom(atom_one_id, Some(postcard::to_allocvec(atom_one).unwrap()));

      // Create `Something.atom_two`.
      if let Some(atom_two) = atom_two {
        let atom_two_id = rng.gen();
        store.set_edge(rng.gen(), Some((id, Something::ATOM_TWO_LABEL, atom_two_id)));
        store.set_atom(atom_two_id, Some(postcard::to_allocvec(atom_two).unwrap()));
      } else {
        store.set_edge(rng.gen(), Some((id, Something::ATOM_TWO_LABEL, rng.gen())));
      }

      // Create `Something.link_one`.
      store.set_edge(rng.gen(), Some((id, Something::LINK_ONE_LABEL, link_one.id())));

      // Create `Something.link_two`.
      if let Some(link_two) = link_two {
        store.set_edge(rng.gen(), Some((id, Something::LINK_TWO_LABEL, link_two.id())));
      } else {
        store.set_edge(rng.gen(), Some((id, Something::LINK_TWO_LABEL, rng.gen())));
      }

      // Create `Something.link_three`.
      if let Some(link_three) = link_three {
        store.set_edge(rng.gen(), Some((id, Something::LINK_THREE_LABEL, link_three.id())));
      } else {
        store.set_edge(rng.gen(), Some((id, Something::LINK_THREE_LABEL, rng.gen())));
      }
    });

    // Return.
    Self::get(id).unwrap()
  }

  pub fn remove(self) {
    global::access_store_with(|store| store.set_node(self.id, None));
  }
}

impl Model for Something {
  fn id(&self) -> u128 {
    self.id
  }

  fn get(id: u128) -> Option<Self> {
    global::access_store_with(|store| {
      // Variables for existing data.
      let mut atom_one: Option<Atom<String>> = None;
      let mut atom_two: Option<AtomOption<String>> = None;
      let mut link_one: Option<Link<Trivial>> = None;
      let mut link_two: Option<LinkOption<Trivial>> = None;
      let mut link_three: Option<LinkOption<Something>> = None;

      // Load existing data.
      store.node(id)?;
      for edge in store.query_edge_src(id) {
        let (_, label, dst) = store.edge(edge)?;
        match label {
          Something::ATOM_ONE_LABEL => atom_one = Some(Atom::from_raw(dst)),
          Something::ATOM_TWO_LABEL => atom_two = Some(AtomOption::from_raw(dst)),
          Something::LINK_ONE_LABEL => link_one = Some(Link::from_raw(edge)),
          Something::LINK_TWO_LABEL => link_two = Some(LinkOption::from_raw(edge)),
          Something::LINK_THREE_LABEL => link_three = Some(LinkOption::from_raw(edge)),
          _ => (),
        }
      }

      // Pack together. Fail if a field is not found.
      Some(Self {
        id,
        atom_one: atom_one?,
        atom_two: atom_two?,
        link_one: link_one?,
        link_two: link_two?,
        link_three: link_three?,
        backlink: Backlinks::from_raw(id, Something::LINK_THREE_LABEL),
      })
    })
  }
}

#[test]
fn object_store_simple() {
  global::init_in_memory();
  global::access_store_with(|store| store.set_node(0, Some(233)));
  global::access_store_with(|store| store.set_node(1, Some(2333)));
  global::access_store_with(|store| store.set_edge(rand::thread_rng().gen(), Some((0, 23333, 1))));
  assert_eq!(global::access_store_with(|store| store.node(0)), Some(233));
  assert_eq!(global::access_store_with(|store| store.node(1)), Some(2333));
  let edges = global::access_store_with(|store| store.query_edge_src(0));
  assert_eq!(edges.len(), 1);
  assert_eq!(global::access_store_with(|store| store.edge(edges[0])), Some((0, 23333, 1)));
}

#[test]
fn atom_link_simple() {
  global::init_in_memory();

  let trivial = Trivial::create();
  let trivial_again = Trivial::create();

  let something = Something::create(&String::from("test"), Some(&String::from("2333")), &trivial, Some(&trivial), None);
  let something_else = Something::create(&String::from("test"), None, &trivial, None, Some(&something));

  let something_id = something.id();
  let something_else_id = something_else.id();

  let something_copy = Something::get(something_id).unwrap();
  let something_else_copy = Something::get(something_else_id).unwrap();

  assert_eq!(something_copy.atom_one.get(), "test");
  assert_eq!(something_copy.atom_two.get().unwrap(), "2333");
  assert_eq!(something_copy.link_one.get().id(), trivial.id());
  assert_eq!(something_copy.link_two.get().unwrap().id(), trivial.id());
  assert!(something_copy.link_three.get().is_none());

  assert_eq!(something_else_copy.atom_one.get(), "test");
  assert!(something_else_copy.atom_two.get().is_none());
  assert_eq!(something_else_copy.link_one.get().id(), trivial.id());
  assert!(something_else_copy.link_two.get().is_none());
  assert_eq!(something_else_copy.link_three.get().unwrap().id(), something.id());

  something_copy.atom_two.set(None);
  assert!(something_copy.atom_two.get().is_none());
  something_copy.atom_two.set(Some(&String::from("gg")));
  assert_eq!(something_copy.atom_two.get().unwrap(), "gg");
  something_copy.link_two.set(None);
  assert!(something_copy.link_two.get().is_none());
  something_copy.link_two.set(Some(&trivial_again));
  assert_eq!(something_copy.link_two.get().unwrap().id(), trivial_again.id());

  assert_eq!(something.backlink.get().len(), 1);
  assert_eq!(something_else.backlink.get().len(), 0);
  something.link_three.set(Some(&something));
  assert_eq!(something.backlink.get().len(), 2);
  assert_eq!(something_else.backlink.get().len(), 0);

  trivial.remove();
  trivial_again.remove();
  // something.link_one.get(); // Panics.
  assert!(something.link_two.get().is_none());
  // something_else.link_one.get(); // Panics.
  assert!(something_else.link_two.get().is_none());
  something.remove();
  something_else.remove();
}
