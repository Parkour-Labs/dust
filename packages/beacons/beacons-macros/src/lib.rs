use std::num::Wrapping;

use proc_macro2::{Span, TokenStream};
use quote::quote;
use syn::{parse_macro_input, spanned::Spanned, Ident, ItemStruct, LitInt};

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

/// Rewrites a struct with an id field added in.
fn rewrite_struct(item_struct: &ItemStruct) -> TokenStream {
  let name = &item_struct.ident;
  let vis = &item_struct.vis;
  let mut fields = vec![];
  match &item_struct.fields {
    syn::Fields::Named(named) => {
      for val in &named.named {
        if let Some(ident) = &val.ident {
          if ident == "id" {
            panic!("Field with name id is not allowed. Beacons will automatically generate for you.");
          }
        }
        fields.push(val);
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
///
/// The generated code should look something like this:
///
/// ```rust
/// pub const #var_name: u64 = fnv64_hash(#hash_name);
/// ```
fn create_label(var_name: impl AsRef<str>, hash_name: impl AsRef<str>, call_site: Span) -> TokenStream {
  let name = Ident::new(var_name.as_ref(), call_site);
  let hash_val = LitInt::new(&format!("{}", fnv64_hash(hash_name)), call_site);
  quote! {
    pub const #name: u64 = #hash_val;
  }
}

fn create_labels_for_struct(item_struct: &ItemStruct) -> TokenStream {
  let mut labels = vec![];
  labels.push(create_label("LABEL", item_struct.ident.to_string(), item_struct.ident.span()));
  match &item_struct.fields {
    syn::Fields::Named(named) => {
      for val in &named.named {
        let ident = val.ident.as_ref().expect("Failed to unwrap the name of a named field.");
        labels.push(create_label(format!("{}_Label", ident), format!("{}.{}", item_struct.ident, ident), val.span()));
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

#[proc_macro_attribute]
pub fn model(_attrs: proc_macro::TokenStream, tokens: proc_macro::TokenStream) -> proc_macro::TokenStream {
  let item_struct = parse_macro_input!(tokens as ItemStruct);
  let name = &item_struct.ident;
  let struct_def = rewrite_struct(&item_struct);

  let labels = create_labels_for_struct(&item_struct);

  quote! {
    #struct_def

    impl #name {
      #labels
    }
  }
  .into()
}

#[cfg(test)]
mod test {
  use super::*;
  use syn::parse_str;

  fn check_res(expected: impl AsRef<str>, res: &TokenStream) {
    let expected = parse_str::<TokenStream>(expected.as_ref()).unwrap();
    let left_str = format!("{}", expected);
    let right_str = format!("{}", res);
    assert_eq!(left_str, right_str)
  }

  #[test]
  fn test_rewrite_struct() {
    let item_struct = parse_str::<ItemStruct>("pub struct Trivial { name: String, }").unwrap();
    let res = rewrite_struct(&item_struct);
    check_res("pub struct Trivial { id: u128, name: String, }", &res);
  }
}
