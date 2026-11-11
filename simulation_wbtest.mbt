///|
test "adaptive Sod run reaches exact target and audits boundary contributions" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 80)
  let (l, r) = Sod.states()
  let initial = Simulation::new(g, m, g.shock_tube(m, l, r, 0.5))
  let output = initial.run_until(0.2, SolverConfig::standard())
  assert_eq(output.time(), 0.2)
  assert_true(output.steps() > 10)
  assert_true(output.diagnostics().min_pressure > 0.0)
  assert_true(output.conservation_residual().max_abs() < 1.0e-11)
  assert_eq(initial.time(), 0.0)
  let copy = output.cells()
  copy[0] = Conserved::zero()
  assert_true(output.cells()[0].mass > 0.0)
}

///|
test "run rejects backward time and bounded exhaustion" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 8)
  let s = Simulation::new(
    g,
    m,
    g.uniform(m, Primitive::new(1.0, 0.0, 1.0)),
    time=0.2,
  )
  let bad = Some(s.run_until(0.1, SolverConfig::standard())) catch { _ => None }
  assert_true(bad is None)
  let config = SolverConfig::new(
    Periodic,
    Constant,
    Hll,
    ForwardEuler,
    max_steps=1,
  )
  let stop = Some(s.run_until(1.0, config)) catch { _ => None }
  assert_true(stop is None)
}
