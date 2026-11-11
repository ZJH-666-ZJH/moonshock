///|
fn main {
  try {
    let gas = @gas.Gas::new(1.4)
    let mesh = @gas.Mesh::new(0.0, 1.0, 96)
    let (left, right) = @gas.TubeCase::Sod.states()
    let experiment = @gas.Experiment::new(
      "Sod",
      gas,
      mesh,
      left,
      right,
      0.5,
      0.15,
      @gas.SolverConfig::standard(),
    )
    let result = experiment.run()
    assert_true(result.reference_unaffected_by_boundaries)
    assert_true(result.density_error.l1 < 0.04)
    assert_true(result.simulation.conservation_residual().max_abs() < 1.0e-11)
    println("Sod: cells=96, t=0.15, L1=\{result.density_error.l1}")
    println(result.simulation.diagnostics().to_json().stringify())
  } catch {
    error => abort("Sod example failed: \{error}")
  }
}
