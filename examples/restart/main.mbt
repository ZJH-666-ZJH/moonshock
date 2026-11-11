///|
fn main {
  try {
    let gas = @gas.Gas::new(1.4)
    let mesh = @gas.Mesh::new(0.0, 1.0, 48)
    let (left, right) = @gas.TubeCase::Sod.states()
    let config = @gas.SolverConfig::standard()
    let start = @gas.Simulation::new(
      gas,
      mesh,
      gas.shock_tube(mesh, left, right, 0.5),
    )
    let half = start.run_until(0.05, config)
    let resumed = @gas.restore_checkpoint(half.checkpoint())
    let (finished, monitors) = resumed.observe(
      [0.075, 0.1],
      [0.25, 0.5, 0.75],
      config,
    )
    let direct = half.run_until(0.075, config).run_until(0.1, config)
    assert_eq(finished.cells(), direct.cells())
    let loaded = gas.import_csv(mesh, finished.profile_csv())
    assert_true(
      gas.diagnostics(mesh, loaded).totals
      .minus(finished.diagnostics().totals)
      .max_abs() <
      1.0e-12,
    )
    let fine = finished.remeshed(@gas.Mesh::new(0.0, 1.0, 96))
    assert_true(
      fine.diagnostics().totals.minus(finished.diagnostics().totals).max_abs() <
      1.0e-12,
    )
    assert_eq(monitors.length(), 2)
    println("restart, timed probes, CSV and conservative remap passed")
    println(monitors[1].to_json().stringify())
  } catch {
    error => abort("Restart example failed: \{error}")
  }
}
