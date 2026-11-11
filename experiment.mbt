///|
/// A complete named shock-tube experiment. Construction validates all inputs.
pub struct Experiment {
  name : String
  gas : Gas
  mesh : Mesh
  left : Primitive
  right : Primitive
  interface_at : Double
  end_time : Double
  config : SolverConfig
} derive(Debug)

///|
pub fn Experiment::new(
  name : String,
  gas : Gas,
  mesh : Mesh,
  left : Primitive,
  right : Primitive,
  interface_at : Double,
  end_time : Double,
  config : SolverConfig,
) -> Experiment raise GasError {
  if name.length() == 0 || name.length() > 128 {
    raise Invalid("experiment name needs 1..128 code units")
  }
  if !finite(end_time) || end_time <= 0.0 {
    raise Invalid("experiment end time must be positive and finite")
  }
  if !finite(interface_at) ||
    interface_at <= mesh.left ||
    interface_at >= mesh.right {
    raise Invalid("experiment interface must be interior")
  }
  ignore(gas.riemann(left, right))
  { name, gas, mesh, left, right, interface_at, end_time, config, }
}

///|
pub(all) struct ExperimentResult {
  name : String
  simulation : Simulation
  density_error : ErrorNorm
  reference_unaffected_by_boundaries : Bool
} derive(Debug)

///|
/// Runs a gas experiment and labels whether waves have reached either boundary.
/// Exact Riemann comparisons are meaningful only before boundary interactions,
/// and for an outflow experiment; the flag encodes both conditions.
pub fn Experiment::run(self : Experiment) -> ExperimentResult raise GasError {
  let exact = self.gas.riemann(self.left, self.right)
  let initial = self.gas.shock_tube(
    self.mesh,
    self.left,
    self.right,
    self.interface_at,
  )
  let simulation = Simulation::new(self.gas, self.mesh, initial).run_until(
    self.end_time,
    self.config,
  )
  let reference = exact.profile(self.mesh, self.end_time, self.interface_at)
  let speeds = exact.wave_speeds()
  let outflow = self.config.boundaries == Ends(Outflow, Outflow)
  let unaffected = outflow &&
    self.interface_at + speeds[0] * self.end_time > self.mesh.left &&
    self.interface_at + speeds[3] * self.end_time < self.mesh.right
  {
    name: self.name,
    simulation,
    density_error: self.gas.density_error(
      self.mesh,
      simulation.cells,
      reference,
    ),
    reference_unaffected_by_boundaries: unaffected,
  }
}

///|
pub(all) enum BatchOutcome {
  Succeeded(ExperimentResult)
  Failed(String, String)
} derive(Debug)

///|
/// Isolated outcomes let an embedding application report a numerical failure
/// without dropping later experiments. Every individual run retains its budgets.
pub fn run_batch(
  experiments : Array[Experiment],
) -> Array[BatchOutcome] raise GasError {
  if experiments.length() > 1000 {
    raise Invalid("batch exceeds 1000 experiments")
  }
  let output = []
  for experiment in experiments {
    let outcome = Succeeded(experiment.run()) catch {
      GasError::Invalid(message) | GasError::Numerical(message) =>
        Failed(experiment.name, message)
    }
    output.push(outcome)
  }
  output
}

///|
pub extend Experiment with @debug.Debug::{to_repr}

///|
pub extend ExperimentResult with @debug.Debug::{to_repr}

///|
pub extend BatchOutcome with @debug.Debug::{to_repr}
