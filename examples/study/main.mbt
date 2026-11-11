///|
fn main {
  try {
    let gas = @gas.Gas::new(1.4)
    let config = @gas.SolverConfig::new(
      @gas.Boundaries::Periodic,
      @gas.Reconstruction::MonotonizedCentral,
      @gas.FluxMethod::Hll,
      @gas.Integrator::SspRk2,
    )
    let rows = gas.entropy_convergence(
      0.0,
      1.0,
      [24, 48, 96],
      1.0,
      0.2,
      0.7,
      1.0,
      0.15,
      config,
    )
    assert_true(rows[2].error.l1 < rows[0].error.l1)
    for row in rows {
      println(
        "cells=\{row.cells}, L1=\{row.error.l1}, order=\{row.observed_order.unwrap_or(0.0)}",
      )
    }
    let (left, right) = @gas.TubeCase::Sod.states()
    let e = @gas.Experiment::new(
      "portable",
      gas,
      @gas.Mesh::new(0.0, 1.0, 32),
      left,
      right,
      0.5,
      0.05,
      @gas.SolverConfig::standard(),
    )
    let roundtrip = @gas.parse_experiment(e.json_config())
    let outcomes = @gas.run_batch([e, roundtrip])
    assert_eq(outcomes.length(), 2)
    for outcome in outcomes {
      match outcome {
        @gas.BatchOutcome::Succeeded(result) =>
          assert_true(result.density_error.l1 < 0.1)
        @gas.BatchOutcome::Failed(name, message) => abort("\{name}: \{message}")
      }
    }
    println("configuration and independent batch study passed")
  } catch {
    error => abort("Study example failed: \{error}")
  }
}
