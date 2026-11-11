///|
/// Exact non-vacuum ideal-gas Riemann star state and root residual.
pub struct Riemann {
  gas : Gas
  left : Primitive
  right : Primitive
  pressure : Double
  velocity : Double
  residual : Double
  iterations : Int32
} derive(Debug)

///|
pub fn Riemann::pressure(self : Riemann) -> Double {
  self.pressure
}

///|
pub fn Riemann::velocity(self : Riemann) -> Double {
  self.velocity
}

///|
pub fn Riemann::residual(self : Riemann) -> Double {
  self.residual
}

///|
pub fn Riemann::iterations(self : Riemann) -> Int32 {
  self.iterations
}

///|
fn pressure_function(g : Gas, q : Primitive, c : Double, p : Double) -> Double {
  let gamma = g.gamma
  if p > q.pressure {
    let a = 2.0 / ((gamma + 1.0) * q.rho)
    let b = (gamma - 1.0) / (gamma + 1.0) * q.pressure
    (p - q.pressure) * (a / (p + b)).sqrt()
  } else {
    2.0 *
    c /
    (gamma - 1.0) *
    (@math.pow(p / q.pressure, (gamma - 1.0) / (2.0 * gamma)) - 1.0)
  }
}

///|
/// Bracketed bisection avoids a negative Newton pressure and reports nonconvergence.
pub fn Gas::riemann(
  self : Gas,
  left : Primitive,
  right : Primitive,
) -> Riemann raise GasError {
  let cl = self.sound_speed(left)
  let cr = self.sound_speed(right)
  let delta = right.velocity - left.velocity
  if delta >= 2.0 * (cl + cr) / (self.gamma - 1.0) {
    raise Invalid("vacuum-generating Riemann data are unsupported")
  }
  let evaluate = fn(p : Double) {
    pressure_function(self, left, cl, p) +
    pressure_function(self, right, cr, p) +
    delta
  }
  let mut lo = 0.0
  let mut hi = left.pressure.max(right.pressure)
  let mut expansions = 0
  while evaluate(hi) < 0.0 && expansions < 100 {
    hi = hi * 2.0
    expansions = expansions + 1
  }
  if !finite(hi) || !finite(evaluate(hi)) || evaluate(hi) < 0.0 {
    raise Numerical("unable to bracket star pressure")
  }
  let tolerance = 1.0e-12 * (cl + cr + delta.abs())
  let mut pressure = 0.5 * hi
  let mut residual = evaluate(pressure)
  let mut iterations = 0
  while residual.abs() > tolerance && iterations < 200 {
    if residual > 0.0 {
      hi = pressure
    } else {
      lo = pressure
    }
    pressure = lo + 0.5 * (hi - lo)
    residual = evaluate(pressure)
    iterations = iterations + 1
  }
  if !finite(pressure) ||
    pressure <= 0.0 ||
    !finite(residual) ||
    residual.abs() > tolerance {
    raise Numerical("star pressure root did not converge")
  }
  let velocity = 0.5 *
    (
      left.velocity +
      right.velocity +
      pressure_function(self, right, cr, pressure) -
      pressure_function(self, left, cl, pressure)
    )
  if !finite(velocity) {
    raise Numerical("star velocity overflow")
  }
  { gas: self, left, right, pressure, velocity, residual, iterations, }
}

///|
pub fn Riemann::star_density(
  self : Riemann,
  left_side : Bool,
) -> Double raise GasError {
  let q = if left_side { self.left } else { self.right }
  let ratio = self.pressure / q.pressure
  let a = (self.gas.gamma - 1.0) / (self.gas.gamma + 1.0)
  let density = if ratio > 1.0 {
    q.rho * (ratio + a) / (a * ratio + 1.0)
  } else {
    q.rho * @math.pow(ratio, 1.0 / self.gas.gamma)
  }
  if !finite(density) || density <= 0.0 {
    raise Numerical("star density out of range")
  }
  density
}

///|
pub extend Riemann with @debug.Debug::{to_repr}
