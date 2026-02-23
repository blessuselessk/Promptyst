// src/validate.typ
// Internal validation helpers.
// NOT part of the public API. Import only from src/primitives.typ.
// All symbols prefixed _ to signal internal status.
// Typst has no access modifiers; the prefix convention + file boundary
// is the enforced separation.

#let _require(value, field) = {
  if value == none {
    panic("promptyst: required field '" + field + "' is missing.")
  }
  value
}

#let _require-nonempty(arr, field) = {
  if arr == none or arr.len() == 0 {
    panic("promptyst: field '" + field + "' must not be empty.")
  }
  arr
}

#let _enum-check(value, allowed, field) = {
  if not allowed.contains(value) {
    panic(
      "promptyst: field '" + field + "' must be one of: " +
      allowed.join(", ") + ". Got: " + repr(value)
    )
  }
  value
}
