use std::num::Wrapping;

use proc_macro2::TokenStream;
use quote::quote;
use syn::{parse_macro_input, Field, GenericArgument, Ident, ItemStruct, LitInt, PathArguments, Type};

const LINK: &str = "Link";
const ATOM: &str = "Atom";
const OPTION: &str = "Option";

/// Hashes the string [s] to a value of desired.
fn fnv64_hash(s: impl AsRef<str>) -> u64 {
  const PRIME: Wrapping<u64> = Wrapping(1099511628211);
  const BASIS: Wrapping<u64> = Wrapping(14695981039346656037);
  let mut res = BASIS;
  for c in s.as_ref().chars() {
    let high = Wrapping((c as u64) >> 8);
    let low = Wrapping((c as u64) & 0xFF);
    res = (res * PRIME) ^ low;
    res = (res * PRIME) ^ high;
  }
  res.0
}

/// Converts camel case to snake case.
fn camel_to_snake(camel_case: impl AsRef<str>) -> String {
  let mut snake_case = String::new();
  let mut last_char_was_upper = false;

  for c in camel_case.as_ref().chars() {
    if c.is_ascii_uppercase() {
      if last_char_was_upper {
        snake_case.push('_');
      }
      last_char_was_upper = true;
      snake_case.push(c.to_ascii_lowercase());
    } else {
      last_char_was_upper = false;
      snake_case.push(c);
    }
  }

  snake_case
}

/// Creates the module name.
fn create_mod_name(name: &Ident) -> Ident {
  let snake_case = camel_to_snake(name.to_string());
  Ident::new(&snake_case, name.span())
}

/// Unwraps `Option<Outer<T>>` to `Some<T>`.
fn unwrap_option_wrapper(outer: impl AsRef<str>, ty: &Type) -> Option<&Type> {
  if let Some(ty) = unwrap_type(outer, ty) {
    if let Some(ty) = unwrap_type(OPTION, ty) {
      return Some(ty);
    }
    return Some(ty);
  }
  return None;
}

/// Rewrites a struct with an id field added in.
fn rewrite_struct(item_struct: &ItemStruct) -> TokenStream {
  const ID: &str = "id";
  let name = &item_struct.ident;
  let vis = &item_struct.vis;
  let mut fields = vec![];
  match &item_struct.fields {
    syn::Fields::Named(named) => {
      for val in &named.named {
        if let Some(ident) = &val.ident {
          if ident == ID {
            panic!("Field with name id is not allowed. Beacons will automatically generate for you.");
          }
          if let Some(ty) = unwrap_option_wrapper(ATOM, &val.ty) {
            fields.push(quote! {
              #ident: Atom<#ty>
            });
            continue;
          }
          if let Some(ty) = unwrap_option_wrapper(LINK, &val.ty) {
            fields.push(quote! {
              #ident: Link<#ty>
            });
            continue;
          }
        }
        panic!("Type must be wrapped with either Atom or Link.");
      }
    }
    syn::Fields::Unnamed(_) => {
      panic!("Unnamed structs are not supported yet!");
    }
    syn::Fields::Unit => {}
  };
  quote! {
    #vis struct #name {
      id: u128,
      #(#fields,)*
    }
  }
}

/// Creates a label const. The variable name of the const is given by [var_name], the value of the const is the hashed value given by calling [fnv64_hash] on the [hash_name], and the call_site specifies the location from which the code is generated.
fn create_const_label_declaration(name: &Ident, hash_name: impl AsRef<str>) -> TokenStream {
  let hash_val = LitInt::new(&format!("{}", fnv64_hash(hash_name)), name.span());
  quote! {
    pub const #name: u64 = #hash_val;
  }
}

fn create_label(name: &Ident) -> Ident {
  let name_str = name.to_string().to_uppercase();
  Ident::new(&format!("{}_LABEL", name_str), name.span())
}

/// Creates the label constants for the [item_struct]. This will create a constant named `LABEL` that holds the hash value for the struct's name. For each field, it will create a constant named `FIELDNAME_LABEL` with the value of calling fnv64_hash on `StructName.field_name`.
fn create_labels_for_struct(item_struct: &ItemStruct) -> TokenStream {
  let mut labels = vec![];
  labels.push(create_const_label_declaration(
    &Ident::new("LABEL", item_struct.ident.span()),
    item_struct.ident.to_string(),
  ));
  match &item_struct.fields {
    syn::Fields::Named(named) => {
      for val in &named.named {
        let ident = val.ident.as_ref().expect("Failed to unwrap the name of a named field.");
        labels.push(create_const_label_declaration(&create_label(ident), format!("{}.{}", item_struct.ident, ident)));
      }
    }
    syn::Fields::Unnamed(_) => {
      panic!("Unnamed structs are not supported yet!");
    }
    syn::Fields::Unit => {}
  };
  quote! {
    #(#labels)*
  }
}

fn unwrap_type(wrapper_name: impl AsRef<str>, ty: &Type) -> Option<&Type> {
  match &ty {
    syn::Type::Path(path) => {
      if let Some(segment) = path.path.segments.last() {
        if segment.ident != wrapper_name.as_ref() {
          return None;
        }
        if let PathArguments::AngleBracketed(args) = &segment.arguments {
          if let Some(GenericArgument::Type(ty)) = args.args.last() {
            return Some(ty);
          }
        }
      }
      None
    }
    _ => None,
  }
}

fn create_create_fn_param_from_field(field: &Field) -> TokenStream {
  let name = &field.ident;
  if let Some(ty) = unwrap_type(ATOM, &field.ty) {
    return quote! {
      #name: #ty
    };
  }
  if let Some(ty) = unwrap_type(LINK, &field.ty) {
    return quote! {
      #name: #ty
    };
  }
  panic!("Fields other than Atoms and Links are not supported.");
}

fn create_create_fn_body_for_field(field: &Field) -> TokenStream {
  let name = field.ident.as_ref().expect("Fields must be named.");
  let label = create_label(name);
  if let Some(ty) = unwrap_type(ATOM, &field.ty) {
    if let Some(_) = unwrap_type(OPTION, ty) {
      return quote! {
        {
          if let Some(#name) = #name {
            let tmp_id = rng.gen();
            store.set_edge(rng.gen(), Some((id, Self::#label, tmp_id)));
            store.set_atom(tmp_id, Some(postcard::to_allocvec(#name).unwrap()));
          } else {
            store.set_edge(rng.gen(), Some((id, Self::#label, rng.gen())));
          }
        }
      };
    } else {
      return quote! {
        {
          let tmp_id = rng.gen();
          store.set_edge(rng.gen(), Some((id, Self::#label, tmp_id)));
          store.set_atom(tmp_id, Some(postcard::to_allocvec(#name).unwrap()));
        }
      };
    }
  }
  if let Some(ty) = unwrap_type(LINK, &field.ty) {
    if let Some(_) = unwrap_type(OPTION, ty) {
      return quote! {
         store.set_edge(rng.gen(), Some((id, Self::#label, #name.id())));
      };
    } else {
      return quote! {
        if let Some(#name) = #name {
          store.set_edge(rng.gen(), Some((id, Self::#label, #name.id())));
        } else {
          store.set_edge(rng.gen(), Some((id, Self::#label, rng.gen())));
        }
      };
    }
  }
  panic!("Fields other than Atoms and Links are not supported.");
}

/// Creates the function that creates a new struct
fn create_create_fn(item_struct: &ItemStruct) -> TokenStream {
  let name = &item_struct.ident;
  let fields = &item_struct.fields;
  let mut cst_params = vec![];
  let mut cst_bodies = vec![];
  match fields {
    syn::Fields::Named(named) => {
      for field in &named.named {
        cst_params.push(create_create_fn_param_from_field(&field));
        cst_bodies.push(create_create_fn_body_for_field(&field));
      }
    }
    syn::Fields::Unnamed(_) => {
      panic!("Unnamed structs are not supported yet.")
    }
    syn::Fields::Unit => {}
  };

  quote! {
    pub fn create(#(#cst_params,)*) -> Self {
      let mut rng = rand::thread_rng();
      let id = rng.gen();

      global::access_store_with(|store| {
        store.set_node(id, Some(#name::LABEL));

        #(#cst_bodies)*
      });
      Self::get(id).unwrap()
    }
  }
}

fn create_get_fn_variable(field: &Field) -> TokenStream {
  let name = &field.ident;
  if let Some(ty) = unwrap_option_wrapper(ATOM, &field.ty) {
    return quote! {
      let mut #name: Option<Atom<#ty>> = None;
    };
  }
  if let Some(ty) = unwrap_option_wrapper(LINK, &field.ty) {
    return quote! {
      let mut #name: Optiom<Link<#ty>> = None;
    };
  }
  panic!("Type must be wrapped with either Atom or Link.")
}

fn create_get_fn_match_statement(field: &Field) -> TokenStream {
  let name = &field.ident.as_ref().unwrap();
  let label = create_label(name);
  if let Some(_) = unwrap_option_wrapper(ATOM, &field.ty) {
    return quote! {
      Self::#label => #name = Some(Atom::from_raw(dst)),
    };
  }
  if let Some(_) = unwrap_option_wrapper(LINK, &field.ty) {
    return quote! {
      Self::#label => #name = Some(Link::from_raw(edge)),
    };
  }
  panic!("Type must be wrapped with either Atom or Link.")
}

fn create_get_fn_constructor_args(field: &Field) -> TokenStream {
  let name = &field.ident.as_ref().unwrap();
  quote! {
    #name: #name?,
  }
}

fn create_get_fn(item_struct: &ItemStruct) -> TokenStream {
  let field_declarations = item_struct.fields.iter().map(|x| create_get_fn_variable(x)).collect::<Vec<TokenStream>>();
  let match_statements =
    item_struct.fields.iter().map(|x| create_get_fn_match_statement(x)).collect::<Vec<TokenStream>>();
  let constructor_args =
    item_struct.fields.iter().map(|x| create_get_fn_constructor_args(x)).collect::<Vec<TokenStream>>();
  quote! {
    fn get(id: u128) -> Option<Self> {
      global::access_store_with(|store| {
        #(#field_declarations)*

        store.node(id)?;
        for edge in store.query_edge_src(id) {
          let (_, label, dst) = store.edge(edge)?;
          match label {
            #(#match_statements)*
            _ => (),
          }
        }

        Some(Self {
          id,
          #(#constructor_args)*
        })
      })
    }
  }
}

fn model_impl(item_struct: &ItemStruct) -> TokenStream {
  let name = &item_struct.ident;
  let mod_name = create_mod_name(name);
  let struct_def = rewrite_struct(&item_struct);
  let labels = create_labels_for_struct(&item_struct);
  let create_fn = create_create_fn(&item_struct);
  let get_fn = create_get_fn(&item_struct);

  quote! {
    #struct_def

    pub use #mod_name::*;

    mod #mod_name {
      impl #name {
        #labels

        #create_fn
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
  let item_struct = parse_macro_input!(tokens as ItemStruct);
  model_impl(&item_struct).into()
}

#[cfg(test)]
mod test {
  use super::*;
  #[test]
  fn test1() {
    let s = syn::parse_str::<ItemStruct>("pub struct Something { atom_one: Atom<String>, atom_two: Atom<Option<String>>, link_one: Link<Trivial>, link_two: Link<Option<Trivial>>, }").unwrap();
    let res = model_impl(&s);
    println!("{}", res);
    assert!(false);
  }
}
