///|
test "noncommensurate remap preserves all conserved integrals" {
  let g = Gas::new(1.4)
  let a = Mesh::new(0.0, 1.0, 13)
  let b = Mesh::new(0.0, 1.0, 29)
  let (l, r) = Sod.states()
  let cells = g.shock_tube(a, l, r, 0.39)
  let output = g.remap(a, cells, b)
  assert_true(
    g.diagnostics(a, cells).totals
    .minus(g.diagnostics(b, output).totals)
    .max_abs() <
    1.0e-12,
  )
  assert_true(
    g
    .integrate(a, cells, 0.0, 1.0)
    .minus(g.diagnostics(a, cells).totals)
    .max_abs() <
    1.0e-12,
  )
}

///|
test "remap preserves constant state and rejects mismatched domains" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 7)
  let cells = g.uniform(m, Primitive::new(2.0, 0.2, 1.0))
  let b = Mesh::new(0.0, 1.0, 11)
  let output = g.remap(m, cells, b)
  for u in output {
    assert_true(u.minus(cells[0]).max_abs() < 1.0e-12)
  }
  let bad = Some(g.remap(m, cells, Mesh::new(0.0, 2.0, 11))) catch { _ => None }
  assert_true(bad is None)
}
