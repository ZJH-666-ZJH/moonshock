///|
/// Integrated conserved quantities, minima and resolution-independent diagnostics.
pub(all) struct Diagnostics {
  totals : Conserved
  min_density : Double
  min_pressure : Double
  max_mach : Double
  max_speed : Double
  density_variation : Double
  kinetic_energy : Double
  entropy_integral : Double
} derive(Debug, ToJson)

///|
/// Compensated summation reduces cancellation in long runs and remapping audits.
fn sum_component(cells : Array[Conserved], component : Int32) -> Double {
  let mut sum = 0.0
  let mut correction = 0.0
  for u in cells {
    let value = match component {
      0 => u.mass
      1 => u.momentum
      _ => u.energy
    }
    let adjusted = value - correction
    let next = sum + adjusted
    correction = next - sum - adjusted
    sum = next
  }
  sum
}

///|
pub fn Gas::diagnostics(
  self : Gas,
  mesh : Mesh,
  cells : Array[Conserved],
) -> Diagnostics raise GasError {
  self.validate_cells(mesh, cells)
  let totals = {
    mass: sum_component(cells, 0) * mesh.dx,
    momentum: sum_component(cells, 1) * mesh.dx,
    energy: sum_component(cells, 2) * mesh.dx,
  }
  if !finite(totals.mass) || !finite(totals.momentum) || !finite(totals.energy) {
    raise Numerical("integral overflow")
  }
  let first = self.primitive(cells[0])
  let mut min_density = first.rho
  let mut min_pressure = first.pressure
  let mut max_mach = 0.0
  let mut max_speed = 0.0
  let mut density_variation = 0.0
  let mut previous = first.rho
  let mut kinetic_energy = 0.0
  let mut entropy_integral = 0.0
  for u in cells {
    let q = self.primitive(u)
    min_density = min_density.min(q.rho)
    min_pressure = min_pressure.min(q.pressure)
    max_mach = max_mach.max(self.mach(q).abs())
    max_speed = max_speed.max(self.max_speed(q))
    density_variation = density_variation + (q.rho - previous).abs()
    previous = q.rho
    kinetic_energy = kinetic_energy +
      0.5 * q.rho * q.velocity * q.velocity * mesh.dx
    entropy_integral = entropy_integral +
      q.rho * (@math.ln(q.pressure) - self.gamma * @math.ln(q.rho)) * mesh.dx
  }
  if !finite(kinetic_energy) ||
    !finite(entropy_integral) ||
    !finite(density_variation) {
    raise Numerical("diagnostic overflow")
  }
  {
    totals,
    min_density,
    min_pressure,
    max_mach,
    max_speed,
    density_variation,
    kinetic_energy,
    entropy_integral,
  }
}

///|
pub(all) struct ErrorNorm {
  l1 : Double
  l2 : Double
  linf : Double
} derive(Debug, ToJson)

///|
/// Compare cell-average primitives to an exact center-value reference.
/// At discontinuities this reports the chosen sample convention, not a rigorous bound.
pub fn Gas::density_error(
  self : Gas,
  mesh : Mesh,
  cells : Array[Conserved],
  reference : Array[Primitive],
) -> ErrorNorm raise GasError {
  self.validate_cells(mesh, cells)
  if reference.length() != mesh.cells {
    raise Invalid("reference length differs from mesh")
  }
  let mut l1 = 0.0
  let mut l2 = 0.0
  let mut linf = 0.0
  for i in 0..<mesh.cells {
    reference[i].validate()
    let d = (self.primitive(cells[i]).rho - reference[i].rho).abs()
    l1 = l1 + d / mesh.cells.to_double()
    l2 = l2 + d * d / mesh.cells.to_double()
    linf = linf.max(d)
  }
  if !finite(l1) || !finite(l2) {
    raise Numerical("error norm overflow")
  }
  { l1, l2: l2.sqrt(), linf, }
}

///|
pub extend Diagnostics with @debug.Debug::{to_repr}

///|
pub extend Diagnostics with ToJson::{to_json}

///|
pub extend ErrorNorm with @debug.Debug::{to_repr}

///|
pub extend ErrorNorm with ToJson::{to_json}
