///|
test "batch failures are isolated and successful cases retain error diagnostics" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 32)
  let (l, r) = Sod.states()
  let good = Experiment::new(
    "sod",
    g,
    m,
    l,
    r,
    0.5,
    0.1,
    SolverConfig::standard(),
  )
  let limited = SolverConfig::new(
    Ends(Outflow, Outflow),
    Constant,
    Hll,
    ForwardEuler,
    max_steps=1,
  )
  let exhausted = Experiment::new("limited", g, m, l, r, 0.5, 0.1, limited)
  let result = run_batch([exhausted, good])
  assert_true(result[0] is Failed("limited", _))
  match result[1] {
    Succeeded(r) => {
      assert_true(r.reference_unaffected_by_boundaries)
      assert_true(r.density_error.l1 < 0.1)
    }
    Failed(_, _) => fail("expected successful second experiment")
  }
}

///|
test "reference boundary flag rejects wall interaction comparisons" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 16)
  let (l, r) = Sod.states()
  let config = SolverConfig::new(Ends(Wall, Wall), Constant, Hll, ForwardEuler)
  let e = Experiment::new("wall", g, m, l, r, 0.5, 0.02, config).run()
  assert_false(e.reference_unaffected_by_boundaries)
}
