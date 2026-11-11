///|
fn object_size(value : Json, size : Int32) -> Unit raise GasError {
  match value {
    Object(o) =>
      if o.length() != size {
        raise Invalid("unexpected JSON field count")
      }
    _ => raise Invalid("expected JSON object")
  }
}

///|
fn required_json(value : Json, key : String) -> Json raise GasError {
  match json_field(value, key) {
    Some(v) => v
    None => raise Invalid("missing JSON field: " + key)
  }
}

///|
fn json_text(value : Json, key : String) -> String raise GasError {
  match required_json(value, key) {
    String(s) => s
    _ => raise Invalid("expected JSON string: " + key)
  }
}

///|
fn decode_primitive(value : Json) -> Primitive raise GasError {
  object_size(value, 3)
  Primitive::new(
    json_number(value, "rho"),
    json_number(value, "velocity"),
    json_number(value, "pressure"),
  )
}

///|
fn boundary_name(bc : Boundaries) -> String {
  match bc {
    Periodic => "periodic"
    Ends(Outflow, Outflow) => "outflow"
    Ends(Wall, Wall) => "wall"
    Ends(Wall, Outflow) => "wall-outflow"
    Ends(Outflow, Wall) => "outflow-wall"
  }
}

///|
fn decode_solver(value : Json) -> SolverConfig raise GasError {
  object_size(value, 7)
  let boundaries = match json_text(value, "boundaries") {
    "periodic" => Periodic
    "outflow" => Ends(Outflow, Outflow)
    "wall" => Ends(Wall, Wall)
    "wall-outflow" => Ends(Wall, Outflow)
    "outflow-wall" => Ends(Outflow, Wall)
    _ => raise Invalid("unknown boundary policy")
  }
  let reconstruction = match json_text(value, "reconstruction") {
    "constant" => Constant
    "minmod" => Minmod
    "mc" => MonotonizedCentral
    _ => raise Invalid("unknown reconstruction")
  }
  let flux = match json_text(value, "flux") {
    "hll" => Hll
    "rusanov" => Rusanov
    _ => raise Invalid("unknown numerical flux")
  }
  let integrator = match json_text(value, "integrator") {
    "euler" => ForwardEuler
    "ssprk2" => SspRk2
    _ => raise Invalid("unknown time integrator")
  }
  SolverConfig::new(
    boundaries,
    reconstruction,
    flux,
    integrator,
    cfl=json_number(value, "cfl"),
    max_steps=nonnegative_count(json_number(value, "max_steps")),
    max_retries=nonnegative_count(json_number(value, "max_retries")),
  )
}

///|
/// Strict versioned experiment input. Rejects unknown/missing/duplicate fields,
/// fractional counts, unrecognized policies and configurations outside budgets.
/// The document represents inputs only; it never claims a run was successful.
pub fn parse_experiment(text : String) -> Experiment raise GasError {
  if text.length() > 1000000 {
    raise Invalid("experiment JSON exceeds one million code units")
  }
  let value = @json.parse(text, max_nesting_depth=8, reject_duplicate_keys=true) catch {
    _ => raise Invalid("invalid experiment JSON")
  }
  object_size(value, 9)
  if json_number(value, "schema") != 1.0 {
    raise Invalid("unsupported experiment schema")
  }
  let gas = Gas::new(json_number(value, "gamma"))
  let grid = required_json(value, "mesh")
  object_size(grid, 3)
  let mesh = Mesh::new(
    json_number(grid, "left"),
    json_number(grid, "right"),
    nonnegative_count(json_number(grid, "cells")),
  )
  Experiment::new(
    json_text(value, "name"),
    gas,
    mesh,
    decode_primitive(required_json(value, "left_state")),
    decode_primitive(required_json(value, "right_state")),
    json_number(value, "interface_at"),
    json_number(value, "end_time"),
    decode_solver(required_json(value, "solver")),
  )
}

///|
/// Portable JSON describing precisely the validated inputs used by this experiment.
pub fn Experiment::json_config(self : Experiment) -> String {
  let config = self.config
  let reconstruction = match config.reconstruction {
    Constant => "constant"
    Minmod => "minmod"
    MonotonizedCentral => "mc"
  }
  let flux = match config.flux {
    Hll => "hll"
    Rusanov => "rusanov"
  }
  let integrator = match config.integrator {
    ForwardEuler => "euler"
    SspRk2 => "ssprk2"
  }
  Json::object({
    "schema": Json::number(1.0),
    "name": Json::string(self.name),
    "gamma": Json::number(self.gas.gamma),
    "mesh": Json::object({
      "left": Json::number(self.mesh.left),
      "right": Json::number(self.mesh.right),
      "cells": Json::number(self.mesh.cells.to_double()),
    }),
    "left_state": self.left.to_json(),
    "right_state": self.right.to_json(),
    "interface_at": Json::number(self.interface_at),
    "end_time": Json::number(self.end_time),
    "solver": Json::object({
      "boundaries": Json::string(boundary_name(config.boundaries)),
      "reconstruction": Json::string(reconstruction),
      "flux": Json::string(flux),
      "integrator": Json::string(integrator),
      "cfl": Json::number(config.cfl),
      "max_steps": Json::number(config.max_steps.to_double()),
      "max_retries": Json::number(config.max_retries.to_double()),
    }),
  }).stringify()
}
