///|
/// Validated policy for a bounded simulation. Read-only after construction.
#derive(Debug)
pub struct SolverConfig {
  boundaries : Boundaries
  reconstruction : Reconstruction
  flux : FluxMethod
  integrator : Integrator
  cfl : Double
  max_steps : Int32
  max_retries : Int32
}

///|
pub fn SolverConfig::new(
  boundaries : Boundaries,
  reconstruction : Reconstruction,
  flux : FluxMethod,
  integrator : Integrator,
  cfl~ : Double = 0.4,
  max_steps~ : Int32 = 100000,
  max_retries~ : Int32 = 20,
) -> SolverConfig raise GasError {
  if !finite(cfl) ||
    cfl <= 0.0 ||
    cfl > 0.5 ||
    max_steps < 1 ||
    max_steps > 10000000 ||
    max_retries < 0 ||
    max_retries > 40 {
    raise Invalid("invalid CFL, step budget or retry budget")
  }
  { boundaries, reconstruction, flux, integrator, cfl, max_steps, max_retries, }
}

///|
pub fn SolverConfig::standard() -> SolverConfig {
  {
    boundaries: Ends(Outflow, Outflow),
    reconstruction: MonotonizedCentral,
    flux: Hll,
    integrator: SspRk2,
    cfl: 0.4,
    max_steps: 100000,
    max_retries: 20,
  }
}

///|
/// An immutable snapshot accessor always returns a copy of its mutable array.
#derive(Debug)
pub struct Simulation {
  gas : Gas
  mesh : Mesh
  cells : Array[Conserved]
  time : Double
  steps : Int32
  retries : Int32
  boundary_change : Conserved
  initial_totals : Conserved
}

///|
pub fn Simulation::new(
  gas : Gas,
  mesh : Mesh,
  cells : Array[Conserved],
  time~ : Double = 0.0,
) -> Simulation raise GasError {
  if !finite(time) || time < 0.0 {
    raise Invalid("initial time must be finite and nonnegative")
  }
  let initial = gas.diagnostics(mesh, cells)
  {
    gas,
    mesh,
    cells: cells.copy(),
    time,
    steps: 0,
    retries: 0,
    boundary_change: Conserved::zero(),
    initial_totals: initial.totals,
  }
}

///|
pub fn Simulation::cells(self : Simulation) -> Array[Conserved] {
  self.cells.copy()
}

///|
pub fn Simulation::time(self : Simulation) -> Double {
  self.time
}

///|
pub fn Simulation::steps(self : Simulation) -> Int32 {
  self.steps
}

///|
pub fn Simulation::retries(self : Simulation) -> Int32 {
  self.retries
}

///|
pub fn Simulation::mesh(self : Simulation) -> Mesh {
  self.mesh
}

///|
pub fn Simulation::gas(self : Simulation) -> Gas {
  self.gas
}

///|
pub fn Simulation::diagnostics(self : Simulation) -> Diagnostics raise GasError {
  self.gas.diagnostics(self.mesh, self.cells)
}

///|
pub fn Simulation::conservation_residual(
  self : Simulation,
) -> Conserved raise GasError {
  let result = self.diagnostics().totals
    .minus(self.initial_totals)
    .minus(self.boundary_change)
  if !finite(result.mass) || !finite(result.momentum) || !finite(result.energy) {
    raise Numerical("conservation ledger overflow")
  }
  result
}

///|
/// Runs transactionally: errors do not mutate the source simulation. Step budget
/// applies to this call; cumulative accepted steps remain in the returned value.
pub fn Simulation::run_until(
  self : Simulation,
  end_time : Double,
  config : SolverConfig,
) -> Simulation raise GasError {
  if !finite(end_time) || end_time < self.time {
    raise Invalid("end time precedes snapshot or is nonfinite")
  }
  let mut cells = self.cells.copy()
  let mut time = self.time
  let mut steps = 0
  let mut retries = 0
  let mut boundary_change = self.boundary_change
  while time < end_time {
    if self.steps + steps >= 1000000000 {
      raise Numerical("cumulative step counter exhausted")
    }
    if steps >= config.max_steps {
      raise Numerical("accepted-step budget exhausted")
    }
    let remaining = end_time - time
    let mut dt = self.gas.stable_dt(self.mesh, cells, config.cfl).min(remaining)
    let mut attempt = 0
    let mut accepted : StepResult? = None
    while accepted is None {
      if time + dt <= time || dt <= 0.0 {
        raise Numerical("time cannot advance at machine precision")
      }
      accepted = Some(
        self.gas.advance(
          self.mesh,
          cells,
          dt,
          config.boundaries,
          config.reconstruction,
          config.flux,
          config.integrator,
        ),
      ) catch {
        GasError::Numerical(_) | GasError::Invalid(_) => None
      }
      if accepted is None {
        if attempt >= config.max_retries {
          raise Numerical("physical-state/CFL retry budget exhausted")
        }
        dt = dt * 0.5
        attempt = attempt + 1
        if self.retries + retries >= 1000000000 {
          raise Numerical("cumulative retry counter exhausted")
        }
        retries = retries + 1
      }
    }
    match accepted {
      Some(next) => {
        cells = next.cells
        boundary_change = boundary_change.plus(next.boundary_change)
      }
      None => raise Numerical("internal step acceptance failure")
    }
    time = if dt == remaining { end_time } else { time + dt }
    steps = steps + 1
  }
  {
    gas: self.gas,
    mesh: self.mesh,
    cells,
    time,
    steps: self.steps + steps,
    retries: self.retries + retries,
    boundary_change,
    initial_totals: self.initial_totals,
  }
}

///|
pub extend SolverConfig with @debug.Debug::{to_repr}

///|
pub extend Simulation with @debug.Debug::{to_repr}
