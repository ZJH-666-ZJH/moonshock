///|
fn json_field(value : Json, key : String) -> Json? {
  if value is Object(o) {
    o.get(key)
  } else {
    None
  }
}

///|
fn json_number(object : Json, key : String) -> Double raise GasError {
  match json_field(object, key) {
    Some(value) =>
      match (if value is Number(n, ..) { Some(n) } else { None }) {
        Some(n) =>
          if finite(n) {
            n
          } else {
            raise Invalid("nonfinite checkpoint number")
          }
        None => raise Invalid("checkpoint field must be a number: " + key)
      }
    None => raise Invalid("missing checkpoint field: " + key)
  }
}

///|
/// Portable checkpoint v1. Full integrated boundary ledger is included so
/// conservation audits survive restart. It contains no solver configuration.
pub fn Simulation::checkpoint(self : Simulation) -> String raise GasError {
  ignore(self.diagnostics())
  let states = []
  for u in self.cells {
    states.push(u.to_json())
  }
  let document = Json::object({
    "schema": Json::number(1.0),
    "gamma": Json::number(self.gas.gamma),
    "left": Json::number(self.mesh.left),
    "right": Json::number(self.mesh.right),
    "time": Json::number(self.time),
    "steps": Json::number(self.steps.to_double()),
    "retries": Json::number(self.retries.to_double()),
    "initial_totals": self.initial_totals.to_json(),
    "boundary_change": self.boundary_change.to_json(),
    "cells": Json::array(states),
  })
  document.stringify()
}

///|
fn decode_conserved(value : Json) -> Conserved raise GasError {
  let object = match (if value is Object(o) { Some(o) } else { None }) {
    Some(o) => o
    None => raise Invalid("conserved state must be an object")
  }
  if object.length() != 3 {
    raise Invalid("conserved state must contain exactly mass, momentum, energy")
  }
  {
    mass: json_number(value, "mass"),
    momentum: json_number(value, "momentum"),
    energy: json_number(value, "energy"),
  }
}

///|
fn nonnegative_count(value : Double) -> Int32 raise GasError {
  if value < 0.0 || value > 1000000000.0 || value.to_int().to_double() != value {
    raise Invalid("checkpoint counter outside supported integer range")
  }
  value.to_int()
}

///|
/// Rejects duplicate keys, unknown/missing fields, nonphysical states and huge input.
pub fn restore_checkpoint(text : String) -> Simulation raise GasError {
  if text.length() > 256000000 {
    raise Invalid("checkpoint exceeds 256 million code units")
  }
  let value = @json.parse(
    text,
    max_nesting_depth=16,
    reject_duplicate_keys=true,
  ) catch {
    _ => raise Invalid("invalid checkpoint JSON")
  }
  let object = match (if value is Object(o) { Some(o) } else { None }) {
    Some(o) => o
    None => raise Invalid("checkpoint must be an object")
  }
  if object.length() != 10 {
    raise Invalid("checkpoint must contain exactly the v1 fields")
  }
  if json_number(value, "schema") != 1.0 {
    raise Invalid("unsupported checkpoint schema")
  }
  let gas = Gas::new(json_number(value, "gamma"))
  let array = match json_field(value, "cells") {
    Some(v) =>
      match (if v is Array(a) { Some(a) } else { None }) {
        Some(a) => a
        None => raise Invalid("cells must be an array")
      }
    None => raise Invalid("missing cells")
  }
  let mesh = Mesh::new(
    json_number(value, "left"),
    json_number(value, "right"),
    array.length(),
  )
  let cells = []
  for u in array {
    cells.push(decode_conserved(u))
  }
  let time = json_number(value, "time")
  if time < 0.0 {
    raise Invalid("negative checkpoint time")
  }
  let initial_totals = match json_field(value, "initial_totals") {
    Some(v) => decode_conserved(v)
    None => raise Invalid("missing initial totals")
  }
  let boundary_change = match json_field(value, "boundary_change") {
    Some(v) => decode_conserved(v)
    None => raise Invalid("missing boundary ledger")
  }
  let steps = nonnegative_count(json_number(value, "steps"))
  let retries = nonnegative_count(json_number(value, "retries"))
  gas.validate_cells(mesh, cells)
  let result = {
    gas,
    mesh,
    cells,
    time,
    steps,
    retries,
    boundary_change,
    initial_totals,
  }
  ignore(result.conservation_residual())
  result
}
