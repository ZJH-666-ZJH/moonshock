///|
/// Limited piecewise linear primitive reconstruction, or piecewise constant.
pub(all) enum Reconstruction {
  Constant
  Minmod
  MonotonizedCentral
} derive(Debug, Eq)

///|
fn limited(a : Double, b : Double, mode : Reconstruction) -> Double {
  if a == 0.0 || b == 0.0 || (a > 0.0) != (b > 0.0) {
    return 0.0
  }
  let sign = if a > 0.0 { 1.0 } else { -1.0 }
  match mode {
    Constant => 0.0
    Minmod => sign * a.abs().min(b.abs())
    MonotonizedCentral =>
      sign * (0.5 * (a + b)).abs().min(2.0 * a.abs()).min(2.0 * b.abs())
  }
}

///|
/// Returns left and right face traces for each cell. Density/pressure positivity
/// follows from limiting between neighboring positive cell primitive values.
pub fn reconstruct(
  states : Array[Primitive],
  boundaries : Boundaries,
  mode : Reconstruction,
) -> (Array[Primitive], Array[Primitive]) raise GasError {
  if states.length() < 2 || states.length() > 1000000 {
    raise Invalid("reconstruction needs 2..1000000 cells")
  }
  for q in states {
    q.validate()
  }
  let low = []
  let high = []
  let n = states.length()
  for i in 0..<n {
    let q = states[i]
    let before = if i == 0 {
      boundary_state(states, -1, boundaries)
    } else {
      states[i - 1]
    }
    let after = if i + 1 == n {
      boundary_state(states, n, boundaries)
    } else {
      states[i + 1]
    }
    let dr = limited(q.rho - before.rho, after.rho - q.rho, mode)
    let dv = limited(
      q.velocity - before.velocity,
      after.velocity - q.velocity,
      mode,
    )
    let dp = limited(
      q.pressure - before.pressure,
      after.pressure - q.pressure,
      mode,
    )
    let left = Primitive::new(
      q.rho - 0.5 * dr,
      q.velocity - 0.5 * dv,
      q.pressure - 0.5 * dp,
    )
    let right = Primitive::new(
      q.rho + 0.5 * dr,
      q.velocity + 0.5 * dv,
      q.pressure + 0.5 * dp,
    )
    low.push(left)
    high.push(right)
  }
  (low, high)
}

///|
pub fn Gas::interface_fluxes(
  self : Gas,
  mesh : Mesh,
  states : Array[Conserved],
  boundaries : Boundaries,
  mode : Reconstruction,
  scheme : FluxMethod,
) -> Array[Conserved] raise GasError {
  self.validate_cells(mesh, states)
  let primitives = []
  for u in states {
    primitives.push(self.primitive(u))
  }
  let (low, high) = reconstruct(primitives, boundaries, mode)
  let fluxes = []
  let n = mesh.cells
  match boundaries {
    Periodic => fluxes.push(self.numerical_flux(high[n - 1], low[0], scheme))
    Ends(left, _) => {
      let outside = match left {
        Outflow => low[0]
        Wall => reflected(low[0])
      }
      fluxes.push(self.numerical_flux(outside, low[0], scheme))
    }
  }
  for i in 1..<n {
    fluxes.push(self.numerical_flux(high[i - 1], low[i], scheme))
  }
  match boundaries {
    Periodic => fluxes.push(fluxes[0])
    Ends(_, right) => {
      let outside = match right {
        Outflow => high[n - 1]
        Wall => reflected(high[n - 1])
      }
      fluxes.push(self.numerical_flux(high[n - 1], outside, scheme))
    }
  }
  fluxes
}

///|
pub extend Reconstruction with @debug.Debug::{to_repr}

///|
pub extend Reconstruction with Eq::{equal, not_equal}
