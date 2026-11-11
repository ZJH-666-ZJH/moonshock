///|
test "checkpoint preserves restart state and conservation ledger" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 24)
  let (l, r) = Lax.states()
  let s = Simulation::new(g, m, g.shock_tube(m, l, r, 0.5)).run_until(
    0.03,
    SolverConfig::standard(),
  )
  let restored = restore_checkpoint(s.checkpoint())
  assert_eq(restored.cells(), s.cells())
  assert_eq(restored.steps(), s.steps())
  assert_eq(restored.time(), s.time())
  let a = restored.run_until(0.06, SolverConfig::standard())
  let b = s.run_until(0.06, SolverConfig::standard())
  assert_eq(a.cells(), b.cells())
  assert_true(a.conservation_residual().max_abs() < 1.0e-11)
}

///|
test "checkpoint rejects duplicate keys malformed structure and nonphysical values" {
  for text in ["{}", "[]", "{\"schema\":1,\"schema\":1}", "not json"] {
    let bad = Some(restore_checkpoint(text)) catch { _ => None }
    assert_true(bad is None)
  }
}
