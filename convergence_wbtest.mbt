///|
test "smooth entropy refinement decreases error against analytic cell averages" {
  let g = Gas::new(1.4)
  let c = SolverConfig::new(Periodic, MonotonizedCentral, Hll, SspRk2)
  let rows = g.entropy_convergence(
    0.0,
    1.0,
    [24, 48, 96],
    1.0,
    0.2,
    0.7,
    1.0,
    0.15,
    c,
  )
  assert_true(rows[0].observed_order is None)
  assert_true(
    rows[2].error.l1 < rows[1].error.l1 && rows[1].error.l1 < rows[0].error.l1,
  )
  assert_true(rows[2].conservation_residual.max_abs() < 1.0e-12)
  match rows[2].observed_order {
    Some(p) => assert_true(p > 1.3)
    None => fail("missing convergence order")
  }
}

///|
test "convergence rejects unordered resolutions and nonperiodic references" {
  let g = Gas::new(1.4)
  let c = SolverConfig::new(Periodic, Constant, Rusanov, ForwardEuler)
  let bad = Some(
    g.entropy_convergence(0.0, 1.0, [32, 16], 1.0, 0.2, 0.7, 1.0, 0.1, c),
  ) catch {
    _ => None
  }
  assert_true(bad is None)
  let bad = Some(
    g.entropy_convergence(
      0.0,
      1.0,
      [16, 32],
      1.0,
      0.2,
      0.7,
      1.0,
      0.1,
      SolverConfig::standard(),
    ),
  ) catch {
    _ => None
  }
  assert_true(bad is None)
}
