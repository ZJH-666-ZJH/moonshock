///|
/// Recoverable invalid input or numerical failure. No invalid state is silently clipped.
pub suberror GasError {
  Invalid(String)
  Numerical(String)
} derive(Debug)

///|
/// Primitive state for one ideal gas. Units must be consistent across the experiment.
pub(all) struct Primitive {
  rho : Double
  velocity : Double
  pressure : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
/// A finite heat capacity ratio greater than one.
pub struct Gas {
  gamma : Double
} derive(Debug, Eq)

///|
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
pub fn Gas::new(gamma : Double) -> Gas raise GasError {
  if !finite(gamma) || gamma <= 1.0 {
    raise Invalid("gamma must be finite and greater than one")
  }
  { gamma, }
}

///|
pub fn Gas::gamma(self : Gas) -> Double {
  self.gamma
}

///|
pub fn Primitive::new(
  rho : Double,
  velocity : Double,
  pressure : Double,
) -> Primitive raise GasError {
  let q = { rho, velocity, pressure, }
  q.validate()
  q
}

///|
pub fn Primitive::validate(self : Primitive) -> Unit raise GasError {
  if !finite(self.rho) || self.rho <= 0.0 {
    raise Invalid("density must be finite and positive")
  }
  if !finite(self.pressure) || self.pressure <= 0.0 || !finite(self.velocity) {
    raise Invalid(
      "pressure must be finite and positive; velocity must be finite",
    )
  }
}

///|
pub fn Gas::sound_speed(self : Gas, q : Primitive) -> Double raise GasError {
  q.validate()
  let c = (self.gamma * (q.pressure / q.rho)).sqrt()
  if !finite(c) || c <= 0.0 {
    raise Numerical("sound speed overflow or underflow")
  }
  c
}

///|
pub fn Gas::specific_energy(self : Gas, q : Primitive) -> Double raise GasError {
  q.validate()
  let e = q.pressure / q.rho / (self.gamma - 1.0)
  if !finite(e) || e <= 0.0 {
    raise Numerical("internal energy outside floating point range")
  }
  e
}

///|
pub fn Gas::mach(self : Gas, q : Primitive) -> Double raise GasError {
  let result = q.velocity / self.sound_speed(q)
  if !finite(result) {
    raise Numerical("Mach number overflow")
  }
  result
}

///|
pub extend GasError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Primitive with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Primitive with Eq::{equal, not_equal}

///|
pub extend Primitive with ToJson::{to_json}

///|
pub extend Primitive with @json.FromJson::{from_json}

///|
pub extend Gas with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Gas with Eq::{equal, not_equal}
