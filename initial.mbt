///|
/// Piecewise-constant cell averages integrate a discontinuity even inside a cell.
pub fn Gas::shock_tube(
  self : Gas,
  mesh : Mesh,
  left : Primitive,
  right : Primitive,
  interface_at : Double,
) -> Array[Conserved] raise GasError {
  if !finite(interface_at) ||
    interface_at < mesh.left ||
    interface_at > mesh.right {
    raise Invalid("interface must lie within mesh")
  }
  let ul = self.conserved(left)
  let ur = self.conserved(right)
  let states = []
  for i in 0..<mesh.cells {
    let edge = mesh.edge(i)
    let fraction = ((interface_at - edge) / mesh.dx).max(0.0).min(1.0)
    states.push(ul.scaled(fraction).plus(ur.scaled(1.0 - fraction)))
  }
  self.validate_cells(mesh, states)
  states
}

///|
/// Midpoint point values for an exact reference; these are not exact cell averages.
pub fn Riemann::profile(
  self : Riemann,
  mesh : Mesh,
  time : Double,
  interface_at : Double,
) -> Array[Primitive] raise GasError {
  let result = []
  for i in 0..<mesh.cells {
    result.push(self.at(mesh.center(i), time, interface_at))
  }
  result
}

///|
pub fn Gas::uniform(
  self : Gas,
  mesh : Mesh,
  state : Primitive,
) -> Array[Conserved] raise GasError {
  Array::make(mesh.cells, self.conserved(state))
}

///|
/// A periodic smooth entropy wave: constant pressure and velocity, varying density.
/// Integral cell averages use analytic averaging of the sinusoid.
pub fn Gas::entropy_wave(
  self : Gas,
  mesh : Mesh,
  mean_density : Double,
  amplitude : Double,
  velocity : Double,
  pressure : Double,
  phase : Double,
) -> Array[Conserved] raise GasError {
  let base = Primitive::new(mean_density, velocity, pressure)
  ignore(self.conserved(base))
  if !finite(amplitude) || amplitude.abs() >= mean_density || !finite(phase) {
    raise Invalid("wave amplitude must be finite and smaller than mean density")
  }
  let k = 2.0 * @math.PI / (mesh.right - mesh.left)
  let result = []
  for i in 0..<mesh.cells {
    let x = mesh.center(i) - mesh.left
    let attenuation = @math.sin(0.5 * k * mesh.dx) / (0.5 * k * mesh.dx)
    let rho = mean_density + amplitude * attenuation * @math.sin(k * x + phase)
    result.push(self.conserved(Primitive::new(rho, velocity, pressure)))
  }
  result
}

///|
#derive(Debug, Eq)
pub(all) enum TubeCase {
  Sod
  Lax
  Contact
}

///|
pub fn TubeCase::states(self : TubeCase) -> (Primitive, Primitive) {
  match self {
    Sod =>
      (
        { rho: 1.0, velocity: 0.0, pressure: 1.0, },
        { rho: 0.125, velocity: 0.0, pressure: 0.1, },
      )
    Lax =>
      (
        { rho: 0.445, velocity: 0.698, pressure: 3.528, },
        { rho: 0.5, velocity: 0.0, pressure: 0.571, },
      )
    Contact =>
      (
        { rho: 1.0, velocity: 0.5, pressure: 1.0, },
        { rho: 0.5, velocity: 0.5, pressure: 1.0, },
      )
  }
}

///|
pub extend TubeCase with @debug.Debug::{to_repr}

///|
pub extend TubeCase with Eq::{equal, not_equal}
