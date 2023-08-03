use proc_macro2::TokenStream;
use quote::quote;
use std::num::Wrapping;
use syn::{parse_macro_input, spanned::Spanned};

const ID: &str = "id";
const ATOM: &str = "Atom";
const LINK: &str = "Link";
const ATOM_OPTION: &str = "AtomOption";
const LINK_OPTION: &str = "LinkOption";
const MULTILINKS: &str = "Multilinks";
const BACKLINKS: &str = "Backlinks";
const BACKLINK_ATTRIBUTE: &str = "backlink";
const EXTRA_ID_FIELD_MSG: &str =
  "Field with name `id` is not allowed. Beacons will automatically generate one for you.";
const UNSUPPORTED_FIELD_TYPE_MSG: &str = "Field type must be wrapped inside either one of: `Atom`, `AtomOption`, `Link`, `LinkOption`, `Multilinks` or `Backlinks`.";
const BACKLINK_ANNOT_NOT_FOUND_MSG: &str = "Backlinks must be annotated with `#[backlink(\"StructName.field_name\")]`";
const UNSUPPORTED_TUPLE_STRUCTS: &str = "Tuple structs cannot be used.";
const UNSUPPORTED_GENERIC_STRUCTS: &str = "Generic structs are not supported.";

/// All supported field types.
enum FieldType<'a> {
  Atom(&'a syn::Type),                   // (content type)
  Link(&'a syn::Type),                   // (destination type)
  AtomOption(&'a syn::Type),             // (content type)
  LinkOption(&'a syn::Type),             // (destination type)
  Multilinks(&'a syn::Type, syn::Ident), // (label, destination type)
  Backlinks(&'a syn::Type, syn::Ident),  // (label, source type)
}

/// A field to be mapped.
struct Field<'a> {
  name: &'a syn::Ident,
  vis: &'a syn::Visibility,
  ty: FieldType<'a>,
}

/// A struct to be mapped.
struct Struct<'a> {
  name: &'a syn::Ident,
  vis: &'a syn::Visibility,
  fields: Vec<Field<'a>>,
}

/*
/// An enum to be mapped.
struct Enum {
  name: syn::Ident,
  vis: syn::Visibility,
  variants: Vec<Struct>,
}
*/

/// Hashes the string [s] to a value of desired.
fn fnv64_hash(s: impl AsRef<str>) -> u64 {
  const PRIME: Wrapping<u64> = Wrapping(1099511628211);
  const BASIS: Wrapping<u64> = Wrapping(14695981039346656037);
  let mut res = BASIS;
  for c in s.as_ref().as_bytes() {
    res = (res * PRIME) ^ Wrapping(*c as u64);
  }
  res.0
}

/// Converts camel case to snake case.
fn camel_to_snake(s: impl AsRef<str>) -> String {
  let mut res = String::new();
  let mut last_char_was_upper = false;
  for c in s.as_ref().chars() {
    if c.is_ascii_uppercase() {
      if last_char_was_upper {
        res.push('_');
      }
      last_char_was_upper = true;
      res.push(c.to_ascii_lowercase());
    } else {
      last_char_was_upper = false;
      res.push(c);
    }
  }
  res
}

/// Creates the module name.
fn create_mod_name(name: &syn::Ident) -> syn::Ident {
  let snake_case = camel_to_snake(name.to_string());
  syn::Ident::new(&snake_case, name.span())
}

/// Tries to match the outermost "wrapper" of a type, returning the inner type.
fn try_match_type<'a>(wrapper_name: impl AsRef<str>, ty: &'a syn::Type) -> Option<&'a syn::Type> {
  if let syn::Type::Path(path) = &ty {
    if let Some(segment) = path.path.segments.last() {
      if segment.ident == wrapper_name.as_ref() {
        if let syn::PathArguments::AngleBracketed(args) = &segment.arguments {
          if let Some(syn::GenericArgument::Type(ty)) = args.args.last() {
            return Some(ty);
          }
        }
      }
    }
  }
  None
}

/// Tries to access attribute value in the style of `#[name("value")]`.
fn try_get_attr_value(attr_name: impl AsRef<str>, attrs: &Vec<syn::Attribute>) -> Option<String> {
  for attr in attrs {
    if attr.style == syn::AttrStyle::Outer && attr.path().is_ident(&attr_name) {
      return attr.parse_args::<syn::LitStr>().ok().map(|lit| lit.value());
    }
  }
  None
}

/// Converts [`syn::Field`] to [`Field`].
fn convert_field<'a>(field: &'a syn::Field) -> Field<'a> {
  let name = field.ident.as_ref().expect("Unnamed fields cannot be used.");
  let vis = &field.vis;
  let ty = if let Some(inner) = try_match_type(ATOM, &field.ty) {
    FieldType::Atom(inner)
  } else if let Some(inner) = try_match_type(LINK, &field.ty) {
    FieldType::Link(inner)
  } else if let Some(inner) = try_match_type(ATOM_OPTION, &field.ty) {
    FieldType::AtomOption(inner)
  } else if let Some(inner) = try_match_type(LINK_OPTION, &field.ty) {
    FieldType::LinkOption(inner)
  } else if let Some(inner) = try_match_type(MULTILINKS, &field.ty) {
    let label_name = format!("{}_LABEL", name).to_uppercase();
    let label = syn::Ident::new(&label_name, inner.span());
    FieldType::Multilinks(inner, label)
  } else if let Some(inner) = try_match_type(BACKLINKS, &field.ty) {
    let label_name = try_get_attr_value(BACKLINK_ATTRIBUTE, &field.attrs).expect(BACKLINK_ANNOT_NOT_FOUND_MSG);
    let label_name = syn::Ident::new(&format!("{}_LABEL", label_name.to_uppercase()), inner.span());
    FieldType::Backlinks(inner, label_name)
  } else {
    panic!("{}", UNSUPPORTED_FIELD_TYPE_MSG);
  };
  if name == ID {
    panic!("{}", EXTRA_ID_FIELD_MSG);
  }
  Field { name, vis, ty }
}

/// Converts [`syn::ItemStruct`] to [`Struct`].
fn convert_struct<'a>(item_struct: &'a syn::ItemStruct) -> Struct<'a> {
  let name = &item_struct.ident;
  let vis = &item_struct.vis;
  let fields = match &item_struct.fields {
    syn::Fields::Named(named) => named.named.iter().map(|ref field| convert_field(field)).collect(),
    syn::Fields::Unnamed(_) => panic!("{}", UNSUPPORTED_TUPLE_STRUCTS),
    syn::Fields::Unit => Vec::new(),
  };
  if !item_struct.generics.params.is_empty() {
    panic!("{}", UNSUPPORTED_GENERIC_STRUCTS);
  }
  Struct { name, vis, fields }
}

/// Rewrites a struct with an added `id` field.
fn create_struct(s: &Struct) -> TokenStream {
  let name = &s.name;
  let vis = &s.vis;
  let fields = s.fields.iter().map(|field| {
    let name = &field.name;
    let vis = &field.vis;
    match &field.ty {
      FieldType::Atom(inner) => quote! { #vis #name: Atom<#inner> },
      FieldType::Link(inner) => quote! { #vis #name: Link<#inner> },
      FieldType::AtomOption(inner) => quote! { #vis #name: AtomOption<#inner> },
      FieldType::LinkOption(inner) => quote! { #vis #name: LinkOption<#inner> },
      FieldType::Multilinks(inner, _) => quote! { #vis #name: Multilinks<#inner> },
      FieldType::Backlinks(inner, _) => quote! { #vis #name: Backlinks<#inner> },
    }
  });
  quote! {
    #vis struct #name {
      id: u128,
      #(#fields,)*
    }
  }
}

/// Creates a label const. The variable name of the const is given by [`name`],
/// the value of the const is the hash value given by calling [`fnv64_hash`] on
/// [`hash_name`], and the [`call_site`] specifies the location from where the
/// code is generated.
fn create_const_label_decl(name: &syn::Ident, hash_name: impl AsRef<str>) -> TokenStream {
  let hash_val = syn::LitInt::new(&format!("{}", fnv64_hash(hash_name)), name.span());
  quote! { pub const #name: u64 = #hash_val; }
}

fn create_label(name: &syn::Ident) -> syn::Ident {
  let name_str = name.to_string().to_uppercase();
  syn::Ident::new(&format!("{}_LABEL", name_str), name.span())
}

/// Creates the label constants for the [`item_struct`]. This will create a
/// constant named `LABEL` that holds the hash value for the struct's name.
/// For each field, it will create a constant named `FIELDNAME_LABEL` with the
/// value of calling [`fnv64_hash`] on `StructName.field_name`.
fn create_labels_for_struct(s: &Struct) -> TokenStream {
  let mut labels = Vec::new();
  labels.push(create_const_label_decl(&syn::Ident::new("LABEL", s.name.span()), s.name.to_string()));
  for field in &s.fields {
    labels.push(create_const_label_decl(&create_label(&field.name), format!("{}.{}", s.name, &field.name)));
  }
  quote! { #(#labels)* }
}

fn create_new_fn_param(field: &Field) -> TokenStream {
  let name = &field.name;
  match &field.ty {
    FieldType::Atom(inner) => quote! { #name: &#inner, },
    FieldType::Link(inner) => quote! { #name: &#inner, },
    FieldType::AtomOption(inner) => quote! { #name: Option<&#inner>, },
    FieldType::LinkOption(inner) => quote! { #name: Option<&#inner>, },
    FieldType::Multilinks(_, _) => quote! {},
    FieldType::Backlinks(_, _) => quote! {},
  }
}

fn create_new_fn_body(field: &Field) -> TokenStream {
  let name = &field.name;
  let label = create_label(&field.name);
  match &field.ty {
    FieldType::Atom(_) => quote! {
      let dst = rng.gen();
      store.set_edge(rng.gen(), Some((id, Self::#label, dst)));
      store.set_atom(dst, Some(serialize(#name).unwrap()));
    },
    FieldType::Link(_) => quote! {
      store.set_edge(rng.gen(), Some((id, Self::#label, #name.id())));
    },
    FieldType::AtomOption(_) => quote! {
      if let Some(#name) = #name {
        let dst = rng.gen();
        store.set_edge(rng.gen(), Some((id, Self::#label, dst)));
        store.set_atom(dst, Some(serialize(#name).unwrap()));
      } else {
        store.set_edge(rng.gen(), Some((id, Self::#label, rng.gen())));
      }
    },
    FieldType::LinkOption(_) => quote! {
      if let Some(#name) = #name {
        store.set_edge(rng.gen(), Some((id, Self::#label, #name.id())));
      } else {
        store.set_edge(rng.gen(), Some((id, Self::#label, rng.gen())));
      }
    },
    FieldType::Multilinks(_, _) => quote! {},
    FieldType::Backlinks(_, _) => quote! {},
  }
}

/// Creates the function that creates a new struct.
fn create_new_fn(s: &Struct) -> TokenStream {
  let name = &s.name;
  let params = s.fields.iter().map(create_new_fn_param);
  let bodies = s.fields.iter().map(create_new_fn_body);

  quote! {
    pub fn new(#(#params)*) -> Self {
      let mut rng = rand::thread_rng();
      let id = rng.gen();

      global::access_store_with(|store| {
        store.set_node(id, Some(#name::LABEL));

        #(#bodies)*
      });

      Self::get(id).unwrap()
    }
  }
}

/// Creates the function that deletes an existing struct.
fn create_delete_fn(_s: &Struct) -> TokenStream {
  quote! {
    pub fn delete(self) {
      global::access_store_with(|store| store.set_node(self.id, None));
    }
  }
}

fn create_get_fn_field_decls(field: &Field) -> TokenStream {
  let name = &field.name;
  match &field.ty {
    FieldType::Atom(inner) => quote! { let mut #name: Option<Atom<#inner>> = None; },
    FieldType::Link(inner) => quote! { let mut #name: Option<Link<#inner>> = None; },
    FieldType::AtomOption(inner) => quote! { let mut #name: Option<AtomOption<#inner>> = None; },
    FieldType::LinkOption(inner) => quote! { let mut #name: Option<LinkOption<#inner>> = None; },
    FieldType::Multilinks(_, _) => quote! {},
    FieldType::Backlinks(_, _) => quote! {},
  }
}

fn create_get_fn_match_arms(field: &Field) -> TokenStream {
  let name = &field.name;
  let label = create_label(&field.name);
  match &field.ty {
    FieldType::Atom(_) => quote! { Self::#label => #name = Some(Atom::from_raw(dst)), },
    FieldType::Link(_) => quote! { Self::#label => #name = Some(Link::from_raw(edge)), },
    FieldType::AtomOption(_) => quote! { Self::#label => #name = Some(AtomOption::from_raw(dst)), },
    FieldType::LinkOption(_) => quote! { Self::#label => #name = Some(LinkOption::from_raw(edge)), },
    FieldType::Multilinks(_, _) => quote! {},
    FieldType::Backlinks(_, _) => quote! {},
  }
}

fn create_get_fn_ctor_args(field: &Field) -> TokenStream {
  let name = &field.name;
  match &field.ty {
    FieldType::Atom(_) => quote! { #name: #name?, },
    FieldType::Link(_) => quote! { #name: #name?, },
    FieldType::AtomOption(_) => quote! { #name: #name?, },
    FieldType::LinkOption(_) => quote! { #name: #name?, },
    FieldType::Multilinks(ty, label) => quote! { #name: Multilinks::from_raw(id, #ty::#label), },
    FieldType::Backlinks(ty, label) => quote! { #name: Backlinks::from_raw(id, #ty::#label), },
  }
}

fn create_get_fn(s: &Struct) -> TokenStream {
  let field_decls = s.fields.iter().map(create_get_fn_field_decls).collect::<Vec<TokenStream>>();
  let match_arms = s.fields.iter().map(create_get_fn_match_arms).collect::<Vec<TokenStream>>();
  let ctor_args = s.fields.iter().map(create_get_fn_ctor_args).collect::<Vec<TokenStream>>();

  quote! {
    fn get(id: u128) -> Option<Self> {
      global::access_store_with(|store| {
        #(#field_decls)*

        store.node(id)?;
        for edge in store.query_edge_src(id) {
          let (_, label, dst) = store.edge(edge)?;
          match label {
            #(#match_arms)*
            _ => (),
          }
        }

        Some(Self {
          id,
          #(#ctor_args)*
        })
      })
    }
  }
}

// fn create_phantom_fn(s: &Struct) -> TokenStream {
//   let backlinks = s
//     .fields
//     .iter()
//     .map(|x| &x.ty)
//     .filter_map(|x| match x {
//       FieldType::Backlinks(_, ty, name) => Some((*ty, name)),
//       _ => None,
//     })
//     .collect::<Vec<(&syn::Type, &String)>>();

//   quote! {
//     fn __phantom() {

//     }
//   }
// }

/// The implementation of the [`model`] proc macro. This is extracted out to a
/// separate function just so that it is independent of the [`proc_macro`]
/// trait's types, meaning that this code therefore could be used as a normal
/// function.
fn model_impl(s: &Struct) -> TokenStream {
  let name = &s.name;
  let mod_name = create_mod_name(name);
  let struct_def = create_struct(s);
  let labels = create_labels_for_struct(s);
  let new_fn = create_new_fn(s);
  let delete_fn = create_delete_fn(s);
  let get_fn = create_get_fn(s);

  quote! {
    #struct_def

    pub use #mod_name::*;
    mod #mod_name {
      use super::*;
      use rand::Rng;
      use beacons::global::{self, Atom, AtomOption, Backlinks, Link, LinkOption, Model, Multilinks};
      use beacons::{deserialize, serialize};

      impl #name {
        #labels
        #new_fn
        #delete_fn
      }

      impl Model for #name {
        fn id(&self) -> u128 {
          self.id
        }
        #get_fn
      }
    }
  }
}

/// TODO: document this function.
///
/// For more details, see [https://parkourlabs.feishu.cn/docx/SGi2dLIUUo4MjVxdzsvcxseBnZc](https://parkourlabs.feishu.cn/docx/SGi2dLIUUo4MjVxdzsvcxseBnZc).
#[proc_macro_attribute]
pub fn model(_attrs: proc_macro::TokenStream, tokens: proc_macro::TokenStream) -> proc_macro::TokenStream {
  let item_struct = parse_macro_input!(tokens as syn::ItemStruct);
  model_impl(&convert_struct(&item_struct)).into()
}

#[cfg(test)]
mod test {
  use super::*;

  #[test]
  fn test_trivial() {
    let s = syn::parse_str::<syn::ItemStruct>("pub struct Trivial;").unwrap();
    let res = model_impl(&convert_struct(&s));
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
        #[backlink(\"link_three\")]
        backlink: Backlinks<Something>,
      }
      ",
    )
    .unwrap();
    let res = model_impl(&convert_struct(&s));
    println!("{}", res);
    // assert!(false);
  }
}
