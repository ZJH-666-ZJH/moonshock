///|
test "scheduled probes produce exact requested times and independent output state" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 16)
  let s = Simulation::new(g, m, g.uniform(m, Primitive::new(1.0, 0.2, 1.0)))
  let (output, records) = s.observe(
    [0.0, 0.03, 0.03, 0.07],
    [0.0, 0.5, 1.0],
    SolverConfig::standard(),
  )
  assert_eq(output.time(), 0.07)
  assert_eq(records.length(), 4)
  assert_eq(records[1].time, 0.03)
  assert_eq(records[2].time, 0.03)
  assert_eq(records[0].probes[2].index, 15)
  assert_true(@json.valid(monitors_json(records)))
}

///|
test "observation validates all requests before computation" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 8)
  let s = Simulation::new(g, m, g.uniform(m, Primitive::new(1.0, 0.0, 1.0)))
  let bad = Some(s.observe([0.1, 0.05], [], SolverConfig::standard())) catch {
    _ => None
  }
  assert_true(bad is None)
  let outside = Some(s.probes([1.1])) catch { _ => None }
  assert_true(outside is None)
}
