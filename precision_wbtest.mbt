///|
test "large-offset CSV must reject one-cell shifted coordinates" {
  let g = Gas::new(1.4)
  let m = Mesh::new(1.0e15, 1.0e15 + 1024.0, 256)
  let q = Primitive::new(1.0, 0.0, 1.0)
  let rows = ["x,rho,velocity,pressure"]
  for i in 0..<m.cells {
    rows.push("\{m.center(if i==0 { 1 } else if i==1 { 0 } else { i })},1,0,1")
  }
  let result = Some(g.import_csv(m, rows.join("\n"))) catch { _ => None }
  assert_true(result is None)
  ignore(q)
}

///|
test "cumulative restart counters cannot cross checkpoint-supported limit" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 4)
  let s = Simulation::new(g, m, g.uniform(m, Primitive::new(1.0, 0.0, 1.0)))
  let huge = { ..s, steps: 1000000000, }
  let result = Some(huge.run_until(0.001, SolverConfig::standard())) catch {
    _ => None
  }
  assert_true(result is None)
  assert_eq(huge.time, 0.0)
}

///|
test "translated noncommensurate remap preserves integrals on a large-offset mesh" {
  let g = Gas::new(1.4)
  let a = Mesh::new(1.0e12, 1.0e12 + 1.0, 64)
  let b = Mesh::new(1.0e12, 1.0e12 + 1.0, 96)
  let (l, r) = Sod.states()
  let cells = g.shock_tube(a, l, r, 1.0e12 + 0.5)
  let mapped = g.remap(a, cells, b)
  assert_true(
    g.diagnostics(a, cells).totals
    .minus(g.diagnostics(b, mapped).totals)
    .max_abs() <
    1.0e-12,
  )
}
