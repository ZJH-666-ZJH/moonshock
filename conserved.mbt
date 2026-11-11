///|
/// Cell average or integrated flux: density, momentum and total energy.
pub(all) struct Conserved {
  mass : Double
  momentum : Double
  energy : Double
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn Conserved::zero() -> Conserved {
  { mass: 0.0, momentum: 0.0, energy: 0.0, }
}

///|
pub fn Conserved::plus(self : Conserved, other : Conserved) -> Conserved {
  {
    mass: self.mass + other.mass,
    momentum: self.momentum + other.momentum,
    energy: self.energy + other.energy,
  }
}

///|
pub fn Conserved::minus(self : Conserved, other : Conserved) -> Conserved {
  self.plus(other.scaled(-1.0))
}

///|
pub fn Conserved::scaled(self : Conserved, factor : Double) -> Conserved {
  {
    mass: self.mass * factor,
    momentum: self.momentum * factor,
    energy: self.energy * factor,
  }
}

///|
pub fn Conserved::max_abs(self : Conserved) -> Double {
  self.mass.abs().max(self.momentum.abs()).max(self.energy.abs())
}

///|
pub fn Gas::conserved(self : Gas, q : Primitive) -> Conserved raise GasError {
  q.validate()
  let u = {
    mass: q.rho,
    momentum: q.rho * q.velocity,
    energy: q.pressure / (self.gamma - 1.0) +
    0.5 * q.rho * q.velocity * q.velocity,
  }
  if !finite(u.mass) || !finite(u.momentum) || !finite(u.energy) {
    raise Numerical("conservative conversion overflow")
  }
  u
}

///|
pub fn Gas::primitive(self : Gas, u : Conserved) -> Primitive raise GasError {
  if !finite(u.mass) ||
    !finite(u.momentum) ||
    !finite(u.energy) ||
    u.mass <= 0.0 {
    raise Invalid("nonfinite conserved state or nonpositive mass")
  }
  let velocity = u.momentum / u.mass
  let pressure = (self.gamma - 1.0) * (u.energy - 0.5 * u.momentum * velocity)
  Primitive::new(u.mass, velocity, pressure)
}

///|
pub fn Gas::physical_flux(
  self : Gas,
  q : Primitive,
) -> Conserved raise GasError {
  let u = self.conserved(q)
  let f = {
    mass: u.momentum,
    momentum: u.momentum * q.velocity + q.pressure,
    energy: (u.energy + q.pressure) * q.velocity,
  }
  if !finite(f.mass) || !finite(f.momentum) || !finite(f.energy) {
    raise Numerical("flux overflow")
  }
  f
}

///|
pub fn Gas::max_speed(self : Gas, q : Primitive) -> Double raise GasError {
  let speed = q.velocity.abs() + self.sound_speed(q)
  if !finite(speed) {
    raise Numerical("characteristic speed overflow")
  }
  speed
}

///|
pub extend Conserved with @debug.Debug::{to_repr}

///|
pub extend Conserved with Eq::{equal, not_equal}

///|
pub extend Conserved with ToJson::{to_json}

///|
pub extend Conserved with @json.FromJson::{from_json}
