///|
test "uniform diagnostics agree with analytic integrals" {
  let g = Gas::new(1.4)
  let m = Mesh::new(-1.0, 1.0, 16)
  let q = Primitive::new(2.0, 3.0, 4.0)
  let cells = g.uniform(m, q)
  let d = g.diagnostics(m, cells)
  assert_eq(d.totals.mass, 4.0)
  assert_eq(d.totals.momentum, 12.0)
  assert_true((d.totals.energy - 38.0).abs() < 1.0e-12)
  assert_eq(d.density_variation, 0.0)
  let e = g.density_error(m, cells, Array::make(16, q))
  assert_eq(e.linf, 0.0)
}

///|
test "discrete update matches integrated boundary flux" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 32)
  let (l, r) = Sod.states()
  let a = g.shock_tube(m, l, r, 0.5)
  let next = g.advance(
    m,
    a,
    g.stable_dt(m, a, 0.3),
    Ends(Outflow, Outflow),
    Minmod,
    Hll,
    SspRk2,
  )
  let change = g.diagnostics(m, next.cells).totals.minus(
    g.diagnostics(m, a).totals,
  )
  assert_true(change.minus(next.boundary_change).max_abs() < 1.0e-13)
}
