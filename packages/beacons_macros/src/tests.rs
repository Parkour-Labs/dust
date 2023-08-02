use super::*;

#[test]
fn test_trivial() {
  let s = syn::parse_str::<syn::ItemStruct>("pub struct Trivial;").unwrap();
  let res = model_impl(&convert_struct(s));
  println!("{}", res);
  // assert!(false);
}

#[test]
fn test_something() {
  let s = syn::parse_str::<syn::ItemStruct>(
    "
pub struct Something {
  atom_one: Atom<String>,
  atom_two: AtomOption<String>,
  link_one: Link<Trivial>,
  link_two: LinkOption<Trivial>,
  link_three: LinkOption<Something>,
  multilink: Multilinks<Something>,
  #[backlink(\"Something.link_three\")]
  backlink: Backlinks<Something>,
}
      ",
  )
  .unwrap();
  let res = model_impl(&convert_struct(s));
  println!("{}", res);
  // assert!(false);
}
