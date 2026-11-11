///|
/// Explicit Euler or strong-stability-preserving two-stage Runge-Kutta.
#derive(Debug, Eq)
pub(all) enum Integrator {
  ForwardEuler
  SspRk2
}

///|
/// A candidate step and the boundary contribution used in its conservation audit.
#derive(Debug)
pub(all) struct StepResult {
  cells : Array[Conserved]
  boundary_change : Conserved
}

///|
pub fn Gas::stable_dt(
  self : Gas,
  mesh : Mesh,
  states : Array[Conserved],
  cfl : Double,
) -> Double raise GasError {
  self.validate_cells(mesh, states)
  if !finite(cfl) || cfl <= 0.0 || cfl > 0.5 {
    raise Invalid("CFL must be in (0,0.5]")
  }
  let mut speed = 0.0
  for u in states {
    speed = speed.max(self.max_speed(self.primitive(u)))
  }
  let dt = cfl * mesh.dx / speed
  if !finite(dt) || dt <= 0.0 {
    raise Numerical("unrepresentable CFL timestep")
  }
  dt
}

///|
fn euler_candidate(
  gas : Gas,
  mesh : Mesh,
  cells : Array[Conserved],
  dt : Double,
  bc : Boundaries,
  mode : Reconstruction,
  scheme : FluxMethod,
) -> StepResult raise GasError {
  let flux = gas.interface_fluxes(mesh, cells, bc, mode, scheme)
  let output = []
  for i in 0..<mesh.cells {
    let u = cells[i].minus(flux[i + 1].minus(flux[i]).scaled(dt / mesh.dx))
    ignore(gas.primitive(u))
    output.push(u)
  }
  {
    cells: output,
    boundary_change: flux[0].minus(flux[mesh.cells]).scaled(dt),
  }
}

///|
/// The input array is never mutated, including when a stage fails.
/// Stage CFL is checked for both RK evaluations; caller may retry with a smaller dt.
pub fn Gas::advance(
  self : Gas,
  mesh : Mesh,
  cells : Array[Conserved],
  dt : Double,
  bc : Boundaries,
  mode : Reconstruction,
  scheme : FluxMethod,
  integrator : Integrator,
) -> StepResult raise GasError {
  if !finite(dt) || dt <= 0.0 {
    raise Invalid("step dt must be positive and finite")
  }
  if dt > self.stable_dt(mesh, cells, 0.5) * (1.0 + 1.0e-12) {
    raise Numerical("timestep violates cell CFL bound")
  }
  let first = euler_candidate(self, mesh, cells, dt, bc, mode, scheme)
  match integrator {
    ForwardEuler => first
    SspRk2 => {
      if dt > self.stable_dt(mesh, first.cells, 0.5) * (1.0 + 1.0e-12) {
        raise Numerical("RK stage violates CFL bound")
      }
      let second = euler_candidate(
        self,
        mesh,
        first.cells,
        dt,
        bc,
        mode,
        scheme,
      )
      let result = []
      for i in 0..<mesh.cells {
        let u = cells[i].plus(second.cells[i]).scaled(0.5)
        ignore(self.primitive(u))
        result.push(u)
      }
      {
        cells: result,
        boundary_change: first.boundary_change
        .plus(second.boundary_change)
        .scaled(0.5),
      }
    }
  }
}

///|
pub extend Integrator with @debug.Debug::{to_repr}

///|
pub extend Integrator with Eq::{equal, not_equal}

///|
pub extend StepResult with @debug.Debug::{to_repr}
