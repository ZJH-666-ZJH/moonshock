///|
/// One completed resolution of an analytic periodic entropy-wave study.
pub(all) struct ConvergenceRow {
  cells : Int32
  dx : Double
  error : ErrorNorm
  observed_order : Double?
  steps : Int32
  conservation_residual : Conserved
} derive(Debug)

///|
/// Run a resolution study against analytic cell averages, not midpoint samples.
/// Resolutions must strictly increase. An order is reported only for positive
/// successive errors; a zero error cannot yield a meaningful logarithmic ratio.
/// Periodicity is required so the reference remains valid after a full transit.
pub fn Gas::entropy_convergence(
  self : Gas,
  left : Double,
  right : Double,
  resolutions : Array[Int32],
  mean_density : Double,
  amplitude : Double,
  velocity : Double,
  pressure : Double,
  end_time : Double,
  config : SolverConfig,
) -> Array[ConvergenceRow] raise GasError {
  if resolutions.length() < 2 || resolutions.length() > 12 {
    raise Invalid("convergence study requires 2..12 resolutions")
  }
  if config.boundaries != Periodic {
    raise Invalid("entropy study needs periodic boundaries")
  }
  if !finite(end_time) || end_time <= 0.0 {
    raise Invalid("study time must be positive and finite")
  }
  let mut previous_cells = 0
  // Validate the complete request before spending time on the first simulation.
  for n in resolutions {
    if n <= previous_cells {
      raise Invalid("resolutions must strictly increase")
    }
    ignore(Mesh::new(left, right, n))
    previous_cells = n
  }
  let phase = -2.0 * @math.PI * velocity * end_time / (right - left)
  if !finite(phase) {
    raise Invalid("analytic phase overflow")
  }
  let output = []
  let mut previous_error = 0.0
  let mut previous_dx = 0.0
  for n in resolutions {
    let mesh = Mesh::new(left, right, n)
    let initial = self.entropy_wave(
      mesh, mean_density, amplitude, velocity, pressure, 0.0,
    )
    let reference = self.entropy_wave(
      mesh, mean_density, amplitude, velocity, pressure, phase,
    )
    let exact = reference.map(u => self.primitive(u))
    let simulation = Simulation::new(self, mesh, initial).run_until(
      end_time, config,
    )
    let error = self.density_error(mesh, simulation.cells, exact)
    let observed_order = if previous_error > 0.0 && error.l1 > 0.0 {
      let order = @math.ln(previous_error / error.l1) /
        @math.ln(previous_dx / mesh.dx)
      if finite(order) {
        Some(order)
      } else {
        None
      }
    } else {
      None
    }
    output.push({
      cells: n,
      dx: mesh.dx,
      error,
      observed_order,
      steps: simulation.steps,
      conservation_residual: simulation.conservation_residual(),
    })
    previous_error = error.l1
    previous_dx = mesh.dx
  }
  output
}

///|
pub extend ConvergenceRow with @debug.Debug::{to_repr}
